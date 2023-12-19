#!/bin/bash

set -e

TARGET_BRANCHES=("main")

install_java() {
  # TODO: let's think about using BK agent which has Java installed
  #   Current caveat is Logstash BK agent doesn't support docker operatioins in it
  sudo apt update && sudo apt install -y openjdk-17-jdk && sudo apt install -y openjdk-17-jre
}

# Resolves the branches we are going to track
resolve_latest_branches() {
  source .buildkite/scripts/snyk/resolve_stack_version.sh
  for SNAPSHOT_VERSION in "${SNAPSHOT_VERSIONS[@]}"
  do
    IFS='.'
    read -a versions <<< "$SNAPSHOT_VERSION"
    version=${versions[0]}.${versions[1]}
    TARGET_BRANCHES+=("$version")
  done
}

# Build Logstash specific branch to generate Gemlock file where Snyk scans
build_logstash() {
  git reset --hard HEAD # reset if any generated files appeared
  git checkout "$1"
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
  echo "Reporting to Snyk..."
  REMOTE_REPO_URL=$1
  if [ "$REMOTE_REPO_URL" != "main" ]; then
    MAJOR_VERSION=$(echo "$REMOTE_REPO_URL"| cut -d'.' -f 1)
    REMOTE_REPO_URL="$MAJOR_VERSION".latest
    echo "Using '$REMOTE_REPO_URL' remote repo url."
  fi

  # adding git commit hash to Snyk tag to improve visibility
  GIT_HEAD=$(git rev-parse --short HEAD 2> /dev/null)
  ./snyk monitor --all-projects --org=logstash --remote-repo-url="$REMOTE_REPO_URL" --target-reference="$REMOTE_REPO_URL" --detection-depth=6 --exclude=qa,tools,devtools,requirements.txt --project-tags=branch="$TARGET_BRANCH",git_head="$GIT_HEAD" && true
}

install_java
resolve_latest_branches
download_auth_snyk

# clone Logstash repo, build and report
for TARGET_BRANCH in "${TARGET_BRANCHES[@]}"
do
  # check if branch exists
  if git show-ref --quiet refs/heads/"$TARGET_BRANCH"; then
    echo "Using $TARGET_BRANCH branch."
    build_logstash "$TARGET_BRANCH"
    report "$TARGET_BRANCH"
  else
    echo "$TARGET_BRANCH branch doesn't exist."
  fi
done

# Scan Logstash docker images and report
REPOSITORY_BASE_URL="docker.elastic.co/logstash/"

report_docker_image() {
  image=$1
  project_name=$2
  platform=$3
  echo "Reporting $image to Snyk started..."
  docker pull "$image"
  if [[ $platform != null ]]; then
    ./snyk container monitor "$image" --org=logstash --platform="$platform" --project-name="$project_name" --project-tags=version="$version" && true
  else
    ./snyk container monitor "$image" --org=logstash --project-name="$project_name" --project-tags=version="$version" && true
  fi
}

report_docker_images() {
  version=$1
  echo "Version value: $version"

  image=$REPOSITORY_BASE_URL"logstash:$version-SNAPSHOT"
  snyk_project_name="logstash-$version-SNAPSHOT"
  report_docker_image "$image" "$snyk_project_name"

  image=$REPOSITORY_BASE_URL"logstash-oss:$version-SNAPSHOT"
  snyk_project_name="logstash-oss-$version-SNAPSHOT"
  report_docker_image "$image" "$snyk_project_name"

  image=$REPOSITORY_BASE_URL"logstash:$version-SNAPSHOT-arm64"
  snyk_project_name="logstash-$version-SNAPSHOT-arm64"
  report_docker_image "$image" "$snyk_project_name" "linux/arm64"

  image=$REPOSITORY_BASE_URL"logstash:$version-SNAPSHOT-amd64"
  snyk_project_name="logstash-$version-SNAPSHOT-amd64"
  report_docker_image "$image" "$snyk_project_name" "linux/amd64"

  image=$REPOSITORY_BASE_URL"logstash-oss:$version-SNAPSHOT-arm64"
  snyk_project_name="logstash-oss-$version-SNAPSHOT-arm64"
  report_docker_image "$image" "$snyk_project_name" "linux/arm64"

  image=$REPOSITORY_BASE_URL"logstash-oss:$version-SNAPSHOT-amd64"
  snyk_project_name="logstash-oss-$version-SNAPSHOT-amd64"
  report_docker_image "$image" "$snyk_project_name" "linux/amd64"
}

resolve_version_and_report_docker_images() {
  git reset --hard HEAD # reset if any generated files appeared
  git checkout "$1"

  # parse version (ex: 8.8.2 from 8.8 branch, or 8.9.0 from main branch)
  versions_file="$PWD/versions.yml"
  version=$(awk '/logstash:/ { print $2 }' "$versions_file")
  report_docker_images "$version"
}

# resolve docker artifact and report
#for TARGET_BRANCH in "${TARGET_BRANCHES[@]}"
#do
#  if git show-ref --quiet refs/heads/"$TARGET_BRANCH"; then
#    echo "Using $TARGET_BRANCH branch for docker images."
#    resolve_version_and_report_docker_images "$TARGET_BRANCH"
#  else
#    echo "$TARGET_BRANCH branch doesn't exist."
#  fi
#done