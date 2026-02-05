#!/usr/bin/env bash
set -euo pipefail

source .buildkite/scripts/common/vm-agent.sh

ARTIFACT_DIR="${PWD}/acceptance-artifacts"
mkdir -p "${ARTIFACT_DIR}"

echo "--- Downloading artifact from build step"
buildkite-agent artifact download "build/*.deb" "${ARTIFACT_DIR}" --step build-arm64-deb-on-x86
mv "${ARTIFACT_DIR}"/build/*.deb "${ARTIFACT_DIR}/"
rmdir "${ARTIFACT_DIR}/build"

echo "--- Downloaded artifacts"
ls -la "${ARTIFACT_DIR}"/*.deb

echo "--- Running bootstrap"
./gradlew clean bootstrap

echo "--- Running acceptance tests"
export LS_ARTIFACTS_PATH="${ARTIFACT_DIR}"
echo "LS_ARTIFACTS_PATH=${LS_ARTIFACTS_PATH}"
./gradlew runAcceptanceTests
