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

./gradlew --stacktrace artifactDockerObservabilitySRE -PfedrampHighMode=true

docker run docker.elastic.co/logstash/logstash-observability-sre:${QUALIFIED_VERSION} \
  logstash -e 'input { generator { count => 3 } } output { stdout { codec => rubydebug } }'

docker tag docker.elastic.co/logstash/logstash-observability-sre:${QUALIFIED_VERSION} pr-built-observability-sre-image

./gradlew observabilitySREsmokeTests --stacktrace