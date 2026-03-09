#!/bin/bash

set -e

QUALIFIED_VERSION="$(.buildkite/scripts/common/qualified-version.sh)"
TARBALL="build/logstash-observability-sre-${QUALIFIED_VERSION}-docker-image.tar.gz"

buildkite-agent artifact download "${TARBALL}" . --step observability-sre-container-build
