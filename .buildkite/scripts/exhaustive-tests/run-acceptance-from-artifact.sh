#!/usr/bin/env bash
set -euo pipefail

# x86 runs on multi-jdk images, ARM runs on regular images
if [[ "${ARCH}" == "x86_64" ]]; then
  source .buildkite/scripts/common/vm-agent-multi-jdk.sh
else
  source .buildkite/scripts/common/vm-agent.sh
fi

# Get current source version - acceptance tests expect this version in filename
SOURCE_VERSION=$(grep '^logstash:' versions.yml | awk '{print $2}')
echo "Source version: ${SOURCE_VERSION}"

# Map architecture to package-specific naming
# deb uses: amd64/arm64, rpm uses: x86_64/aarch64
case "${PKG_TYPE}" in
  deb) [[ "${ARCH}" == "x86_64" ]] && PKG_ARCH="amd64" || PKG_ARCH="arm64" ;;
  rpm) [[ "${ARCH}" == "x86_64" ]] && PKG_ARCH="x86_64" || PKG_ARCH="aarch64" ;;
esac

[[ "${ARTIFACT_TYPE}" == "snapshot" ]] && BASE_URL="https://snapshots.elastic.co/downloads/logstash" || BASE_URL="https://artifacts.elastic.co/downloads/logstash"

ARTIFACT_DIR="${PWD}/acceptance-artifacts"
mkdir -p "${ARTIFACT_DIR}"

# Download artifact and rename to what acceptance tests expect
ARTIFACT_URL="${BASE_URL}/logstash-${LS_VERSION}-${PKG_ARCH}.${PKG_TYPE}"
EXPECTED_FILE="${ARTIFACT_DIR}/logstash-${SOURCE_VERSION}-SNAPSHOT-${PKG_ARCH}.${PKG_TYPE}"

echo "--- Downloading Logstash ${LS_VERSION} ${PKG_ARCH} ${PKG_TYPE}"
echo "URL: ${ARTIFACT_URL}"
echo "Saving as: ${EXPECTED_FILE}"
curl -fsSL -o "${EXPECTED_FILE}" "${ARTIFACT_URL}"

echo "--- Downloaded artifacts"
ls -la "${ARTIFACT_DIR}"

echo "--- Running bootstrap"
./gradlew clean bootstrap

echo "--- Running acceptance tests"
export LS_ARTIFACTS_PATH="${ARTIFACT_DIR}"
echo "LS_ARTIFACTS_PATH=${LS_ARTIFACTS_PATH}"
./gradlew runAcceptanceTests
