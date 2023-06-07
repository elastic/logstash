#!/bin/bash

set -e

TARGET_BRANCH="main"
cd .buildkite/scripts

# Resolves the branch based on ELASTIC_STACK_VERSION
resolve_latest_branch() {
  if [ "$ELASTIC_STACK_VERSION" != "main" ]; then
    source snyk/resolve_stack_version.sh
    # parse major and minor versions
    IFS='.'
    read -a VERSIONS <<< "$ELASTIC_STACK_VERSION"
    TARGET_BRANCH="${VERSIONS[0]}.${VERSIONS[1]}"
  fi
  echo "Using $TARGET_BRANCH branch."
}

# Clones the Logstash repo and builds to generate Gemlock file where Snyk scans
clone_and_build_logstash() {
  echo "Cloning logstash repo..."
  git clone --depth 1 --branch "$TARGET_BRANCH" https://github.com/elastic/logstash.git
  cd logstash && ./gradlew installDefaultGems && cd ..
}

# Downloads snyk distribution
download_snyk() {
  echo "Downloading snyk..."
  curl https://static.snyk.io/cli/latest/snyk-linux -o snyk
  chmod +x ./snyk
}

# Reports vulnerabilities to the Snyk
report() {
  echo "Reporting to Snyk..."
  REMOTE_REPO_URL=$TARGET_BRANCH
  if [ "$REMOTE_REPO_URL" != "$MAIN_BRANCH" ]; then
    MAJOR_VERSION=$(echo "$REMOTE_REPO_URL"| cut -d'.' -f 1)
    REMOTE_REPO_URL="$MAJOR_VERSION".latest
    echo "Using '$REMOTE_REPO_URL' remote repo url."
  fi

  # adding git add to Snyk tag to improve visibility
  GIT_HEAD=$(git rev-parse --short HEAD 2> /dev/null | sed "s/\(.*\)/\1/")

  vault_path=secret/ci/elastic-logstash-filter-elastic-integration/snyk-creds
  SNYK_TOKEN=$(vault read -field=token "${vault_path}")
  ./snyk auth "$SNYK_TOKEN"
  ./snyk monitor --all-projects --org=logstash --remote-repo-url="$REMOTE_REPO_URL" --target-reference="$REMOTE_REPO_URL" --detection-depth=6 --project-tags=branch="$TARGET_BRANCH",git_head="$GIT_HEAD"
}

resolve_latest_branch
clone_and_build_logstash
cd logstash
download_snyk
report