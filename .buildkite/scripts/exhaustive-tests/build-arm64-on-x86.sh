#!/usr/bin/env bash
set -euo pipefail

source .buildkite/scripts/common/vm-agent.sh

echo "--- Building ARM64 deb and rpm packages on x86_64"
export ARCH="aarch64"
./gradlew clean bootstrap artifactDeb artifactRpm

echo "--- Built artifacts"
ls -la build/*.deb build/*.rpm
