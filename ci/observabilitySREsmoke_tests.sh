#!/bin/bash

set -e

# TODO: Remove once the `platform-ingest-logstash-ubuntu-2204-fips` VM image is
# republished with matching Docker CLI and daemon versions. Currently the CLI
# speaks API v1.53 while the daemon only supports up to v1.43, causing every
# docker/docker-compose command to fail.
export DOCKER_API_VERSION=${DOCKER_API_VERSION:-1.43}

QUALIFIED_VERSION="$(.buildkite/scripts/common/qualified-version.sh)"
STACK_VERSION=$(./gradlew -q printStackVersion)
export ELASTICSEARCH_IMAGE_VERSION="${ELASTICSEARCH_IMAGE_VERSION:-$STACK_VERSION}"
export FILEBEAT_IMAGE_VERSION="${FILEBEAT_IMAGE_VERSION:-$STACK_VERSION}"

IMAGE_NAME="docker.elastic.co/logstash/logstash-observability-sre:${QUALIFIED_VERSION}"
TARBALL="build/logstash-observability-sre-${QUALIFIED_VERSION}-docker-image.tar.gz"

if [[ -f "${TARBALL}" ]]; then
  echo "Loading pre-built image from ${TARBALL}"
  docker load -i "${TARBALL}"
else
  echo "No tarball found, building image locally"
  ./gradlew --stacktrace artifactDockerObservabilitySRE -PfedrampHighMode=true
fi

docker run "${IMAGE_NAME}" \
  logstash -e 'input { generator { count => 3 } } output { stdout { codec => rubydebug } }'

docker tag "${IMAGE_NAME}" pr-built-observability-sre-image

./gradlew observabilitySREsmokeTests --stacktrace
