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
  vault_path=secret/ci/elastic-logstash-filter-elastic-integration/snyk-creds
  SNYK_TOKEN=$(vault read -field=token "${vault_path}")
  ./snyk auth "$SNYK_TOKEN"
  ./snyk monitor --all-projects --org=logstash --remote-repo-url="$TARGET_BRANCH" --target-reference="$TARGET_BRANCH" --detection-depth=6
}

resolve_latest_branch
clone_and_build_logstash
cd logstash
download_snyk
report