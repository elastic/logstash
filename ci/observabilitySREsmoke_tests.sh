#!/bin/bash

set -e

QUALIFIED_VERSION="$(.buildkite/scripts/common/qualified-version.sh)"
STACK_VERSION=$(./gradlew -q printStackVersion)
export ELASTICSEARCH_IMAGE_VERSION="${ELASTICSEARCH_IMAGE_VERSION:-$STACK_VERSION}"
export FILEBEAT_IMAGE_VERSION="${FILEBEAT_IMAGE_VERSION:-$STACK_VERSION}"

./gradlew --stacktrace artifactDockerObservabilitySRE -PfedrampHighMode=true

docker run docker.elastic.co/logstash/logstash-observability-sre:${QUALIFIED_VERSION} \
  logstash -e 'input { generator { count => 3 } } output { stdout { codec => rubydebug } }'

docker tag docker.elastic.co/logstash/logstash-observability-sre:${QUALIFIED_VERSION} pr-built-observability-sre-image

./gradlew observabilitySREsmokeTests --stacktrace