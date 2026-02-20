#!/usr/bin/env bash
set -euo pipefail

source .buildkite/scripts/common/vm-agent.sh

PKG_TYPE="${PKG_TYPE:-deb}"

ARTIFACT_DIR="${PWD}/acceptance-artifacts"
mkdir -p "${ARTIFACT_DIR}"

echo "--- Downloading ${PKG_TYPE} artifact from build step"
buildkite-agent artifact download "build/*.${PKG_TYPE}" "${ARTIFACT_DIR}" --step build-arm64-packages-on-x86
mv "${ARTIFACT_DIR}"/build/*.${PKG_TYPE} "${ARTIFACT_DIR}/"
rmdir "${ARTIFACT_DIR}/build"

echo "--- Downloaded artifacts"
ls -la "${ARTIFACT_DIR}"/*.${PKG_TYPE}

echo "--- Running bootstrap"
./gradlew clean bootstrap

echo "--- Running acceptance tests"
export LS_ARTIFACTS_PATH="${ARTIFACT_DIR}"
echo "LS_ARTIFACTS_PATH=${LS_ARTIFACTS_PATH}"
./gradlew runAcceptanceTests
