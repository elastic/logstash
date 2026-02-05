#!/usr/bin/env bash
set -euo pipefail

source .buildkite/scripts/common/vm-agent.sh

echo "--- Building ARM64 deb package on x86_64"
./gradlew clean bootstrap artifactDeb

echo "--- Built artifacts"
ls -la build/*.deb
