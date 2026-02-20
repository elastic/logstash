#!/usr/bin/env bash
set -euo pipefail

source .buildkite/scripts/common/vm-agent.sh

echo "--- Building ARM64 deb package"
export ARCH="aarch64"
./gradlew clean bootstrap artifactDeb

echo "--- Checking built artifacts"
ls -la build/*.deb || echo "No .deb files found in build/"

echo "--- Running acceptance tests"
export LS_ARTIFACTS_PATH="${PWD}/build"
echo "LS_ARTIFACTS_PATH=${LS_ARTIFACTS_PATH}"
./gradlew runAcceptanceTests
