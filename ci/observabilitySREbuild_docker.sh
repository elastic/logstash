#!/bin/bash

set -e

export ARCH="${ARCH:-x86_64}"

QUALIFIED_VERSION="$(.buildkite/scripts/common/qualified-version.sh)"
IMAGE_NAME="docker.elastic.co/logstash/logstash-observability-sre:${QUALIFIED_VERSION}"
TARBALL_BASE="build/logstash-observability-sre-${QUALIFIED_VERSION}-docker-image.tar"

./gradlew --stacktrace artifactDockerObservabilitySRE -PfedrampHighMode=true

docker save -o "${TARBALL_BASE}" "${IMAGE_NAME}"
gzip "${TARBALL_BASE}"
buildkite-agent artifact upload "${TARBALL_BASE}.gz"
