#!/usr/bin/env bash
set -euo pipefail

# x86 runs on multi-jdk images, ARM runs on regular images
if [[ "${ARCH}" == "x86_64" ]]; then
  source .buildkite/scripts/common/vm-agent-multi-jdk.sh
else
  source .buildkite/scripts/common/vm-agent.sh
fi

# Map architecture to package-specific naming
case "${PKG_TYPE}" in
  deb) [[ "${ARCH}" == "x86_64" ]] && PKG_ARCH="amd64" || PKG_ARCH="arm64" ;;
  rpm) [[ "${ARCH}" == "x86_64" ]] && PKG_ARCH="x86_64" || PKG_ARCH="aarch64" ;;
esac

[[ "${ARTIFACT_TYPE}" == "snapshot" ]] && BASE_URL="https://snapshots.elastic.co/downloads/logstash" || BASE_URL="https://artifacts.elastic.co/downloads/logstash"

ARTIFACT_DIR="${PWD}/acceptance-artifacts"
mkdir -p "${ARTIFACT_DIR}"

echo "--- Downloading Logstash ${LS_VERSION} ${PKG_ARCH} ${PKG_TYPE}"
curl -fsSL -o "${ARTIFACT_DIR}/logstash-${LS_VERSION}-${PKG_ARCH}.${PKG_TYPE}" "${BASE_URL}/logstash-${LS_VERSION}-${PKG_ARCH}.${PKG_TYPE}"

echo "--- Running bootstrap"
./gradlew clean bootstrap

echo "--- Running acceptance tests"
export LS_ARTIFACTS_PATH="${ARTIFACT_DIR}"
./gradlew runAcceptanceTests
