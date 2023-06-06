#!/bin/bash

set -e

MAIN_BRANCH="main"
cd .buildkite/scripts

# Resolves the branch based on ELASTIC_STACK_VERSION
# Clones the Logstash repo and builds
clone_and_build_logstash() {
  BRANCH="$MAIN_BRANCH"
  if [ "$ELASTIC_STACK_VERSION" == "$MAIN_BRANCH" ]; then
    echo "Using $ELASTIC_STACK_VERSION branch."
  else
    source snyk/resolve_stack_version.sh
  fi

  if [ "$ELASTIC_STACK_VERSION" != "$MAIN_BRANCH" ]; then
    # parse major and minor versions
    IFS='.'
    read -a VERSIONS <<< "$ELASTIC_STACK_VERSION"

    BRANCH="${VERSIONS[0]}.${VERSIONS[1]}"
    echo "Using $BRANCH branch."
  fi

  git clone --depth 1 --branch "$BRANCH" https://github.com/elastic/logstash.git
  cd logstash && ./gradlew installDefaultGems && cd ..
}

# Downloads snyk distribution
download_snyk() {
  curl https://static.snyk.io/cli/latest/snyk-linux -o snyk
  chmod +x ./snyk
}

# Reports vulnerabilities to the Snyk
report() {
  REMOTE_REPO_URL=$MAIN_BRANCH
  if [ "$ELASTIC_STACK_VERSION" != "$MAIN_BRANCH" ]; then
    MAJOR_VERSION=$(echo "$ELASTIC_STACK_VERSION"| cut -d'.' -f 1)
    REMOTE_REPO_URL="$MAJOR_VERSION".latest
    echo "Using '$REMOTE_REPO_URL' remote repo url."
  fi

  # TODO: get logstash machine TOKEN from VAULT
  # ./snyk auth "TOKEN"
  # ./snyk monitor --all-projects --org=logstash --remote-repo-url="$REMOTE_REPO_URL" --target-reference="$REMOTE_REPO_URL" --detection-depth=10
}

clone_and_build_logstash
cd logstash
download_snyk
report