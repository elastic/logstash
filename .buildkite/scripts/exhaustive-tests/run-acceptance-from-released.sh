#!/usr/bin/env bash
set -euo pipefail

source .buildkite/scripts/common/vm-agent.sh

echo "--- Getting current source version"
LS_VERSION=$(grep '^logstash:' versions.yml | awk '{print $2}')
echo "Source version: ${LS_VERSION}"

# Use a separate directory to avoid gradle clean wiping it out
ARTIFACT_DIR="${PWD}/acceptance-artifacts"
mkdir -p "${ARTIFACT_DIR}"

echo "--- Downloading Logstash 9.3.0 ARM64 deb"
curl -fsSL -o "${ARTIFACT_DIR}/logstash-${LS_VERSION}-SNAPSHOT-arm64.deb" \
  "https://artifacts.elastic.co/downloads/logstash/logstash-9.3.0-arm64.deb"

echo "--- Checking artifacts"
ls -la "${ARTIFACT_DIR}"/*.deb

echo "--- Running bootstrap"
./gradlew clean bootstrap

echo "--- Running acceptance tests"
export LS_ARTIFACTS_PATH="${ARTIFACT_DIR}"
echo "LS_ARTIFACTS_PATH=${LS_ARTIFACTS_PATH}"
./gradlew runAcceptanceTests
