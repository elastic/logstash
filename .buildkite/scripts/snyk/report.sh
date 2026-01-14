#!/bin/bash

set -e

TARGET_BRANCHES=("main")

install_java_11() {
  curl -L -s "https://github.com/adoptium/temurin11-binaries/releases/download/jdk-11.0.24%2B8/OpenJDK11U-jdk_x64_linux_hotspot_11.0.24_8.tar.gz" | tar -zxf -
}

# Resolves the branches we are going to track
resolve_latest_branches() {
  source .buildkite/scripts/snyk/resolve_stack_version.sh
}

# Build Logstash specific branch to generate Gemlock file where Snyk scans
build_logstash() {
  ./gradlew clean bootstrap assemble installDefaultGems
}

# Downloads snyk distribution
download_auth_snyk() {
  echo "Downloading snyk..."
  curl https://static.snyk.io/cli/latest/snyk-linux -o snyk
  chmod +x ./snyk

  vault_path=secret/ci/elastic-logstash/snyk-creds
  SNYK_TOKEN=$(vault read -field=token "${vault_path}")
  ./snyk auth "$SNYK_TOKEN"
}

# Reports vulnerabilities to the Snyk
report() {
  REMOTE_REPO_URL=$1
  echo "Reporting $REMOTE_REPO_URL branch."
  if [ "$REMOTE_REPO_URL" != "main" ] && [ "$REMOTE_REPO_URL" != "8.x" ]; then
    MAJOR_VERSION=$(echo "$REMOTE_REPO_URL"| cut -d'.' -f 1)
    REMOTE_REPO_URL="$MAJOR_VERSION".latest
    echo "Using '$REMOTE_REPO_URL' remote repo url."
  fi

  # adding git commit hash to Snyk tag to improve visibility
  # for big projects Snyk recommends pruning dependencies
  # https://support.snyk.io/hc/en-us/articles/360002061438-CLI-returns-the-error-Failed-to-get-Vulns
  GIT_HEAD=$(git rev-parse --short HEAD 2> /dev/null)
  ./snyk monitor --prune-repeated-subdependencies --all-projects --org=logstash --remote-repo-url="$REMOTE_REPO_URL" --target-reference="$REMOTE_REPO_URL" --detection-depth=6 --exclude=qa,tools,devtools,requirements.txt --project-tags=branch="$TARGET_BRANCH",git_head="$GIT_HEAD" || :
}

resolve_latest_branches
download_auth_snyk

# clone Logstash repo, build and report
for TARGET_BRANCH in "${TARGET_BRANCHES[@]}"
do
  git reset --hard HEAD # reset if any generated files appeared
  # check if target branch exists
  echo "Checking out $TARGET_BRANCH branch."
  if git checkout "$TARGET_BRANCH"; then
    build_logstash
    report "$TARGET_BRANCH"
  else
    echo "$TARGET_BRANCH branch doesn't exist."
  fi
done
