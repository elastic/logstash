#!/bin/bash

set -e

TARGET_BRANCHES=("main")
cd .buildkite/scripts

install_java() {
  # TODO: let's think about regularly creating a custom image for Logstash which may align on version.yml definitions
  sudo apt update && sudo apt install -y openjdk-17-jdk && sudo apt install -y openjdk-17-jre
}

# Resolves the branches we are going to track
resolve_latest_branches() {
  source snyk/resolve_stack_version.sh
  for SNAPSHOT_VERSION in "${SNAPSHOT_VERSIONS[@]}"
  do
    IFS='.'
    read -a versions <<< "$SNAPSHOT_VERSION"
    version=${versions[0]}.${versions[1]}
    version="${version%\"}"
    version="${version#\"}"
    TARGET_BRANCHES+=("$version")
  done
}

# Clones the Logstash repo
clone_logstash_repo() {
  echo "Cloning logstash repo..."
  git clone https://github.com/elastic/logstash.git
}

# Build Logstash specific branch to generate Gemlock file where Snyk scans
build_logstash() {
  cd logstash
  git reset --hard HEAD # reset if any generated files appeared
  git checkout "$1"
  ./gradlew clean bootstrap assemble installDefaultGems && cd ..
}

# Downloads snyk distribution
download_auth_snyk() {
  cd logstash
  echo "Downloading snyk..."
  curl https://static.snyk.io/cli/latest/snyk-linux -o snyk
  chmod +x ./snyk

  vault_path=secret/ci/elastic-logstash/snyk-creds
  SNYK_TOKEN=$(vault read -field=token "${vault_path}")
  ./snyk auth "$SNYK_TOKEN"
  cd ..
}

# Reports vulnerabilities to the Snyk
report() {
  echo "Reporting to Snyk..."
  cd logstash
  REMOTE_REPO_URL=$1
  if [ "$REMOTE_REPO_URL" != "$MAIN_BRANCH" ]; then
    MAJOR_VERSION=$(echo "$REMOTE_REPO_URL"| cut -d'.' -f 1)
    REMOTE_REPO_URL="$MAJOR_VERSION".latest
    echo "Using '$REMOTE_REPO_URL' remote repo url."
  fi

  # adding git commit hash to Snyk tag to improve visibility
  GIT_HEAD=$(git rev-parse --short HEAD 2> /dev/null)
  ./snyk monitor --all-projects --org=logstash --remote-repo-url="$REMOTE_REPO_URL" --target-reference="$REMOTE_REPO_URL" --detection-depth=6 --exclude=requirements.txt --project-tags=branch="$TARGET_BRANCH",git_head="$GIT_HEAD" && true
  cd ..
}

install_java
resolve_latest_branches
clone_logstash_repo
download_auth_snyk

# clone Logstash repo, build and report
for TARGET_BRANCH in "${TARGET_BRANCHES[@]}"
do
  echo "Using $TARGET_BRANCH branch."
  build_logstash "$TARGET_BRANCH"
  report "$TARGET_BRANCH"
done