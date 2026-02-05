#!/usr/bin/env bash
set -euo pipefail

source .buildkite/scripts/common/vm-agent.sh

echo "--- Getting current source version"
LS_VERSION=$(grep '^logstash:' versions.yml | awk '{print $2}')
echo "Source version: ${LS_VERSION}"

echo "--- Downloading Logstash 9.3.0 ARM64 deb"
mkdir -p build
curl -fsSL -o "build/logstash-${LS_VERSION}-SNAPSHOT-arm64.deb" \
  "https://artifacts.elastic.co/downloads/logstash/logstash-9.3.0-arm64.deb"

echo "--- Checking artifacts"
ls -la build/*.deb

echo "--- Running bootstrap and acceptance tests"
export LS_ARTIFACTS_PATH="${PWD}/build"
echo "LS_ARTIFACTS_PATH=${LS_ARTIFACTS_PATH}"
./gradlew clean bootstrap
./gradlew runAcceptanceTests
