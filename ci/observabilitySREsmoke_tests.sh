#!/bin/bash

set -e

QUALIFIED_VERSION="$(.buildkite/scripts/common/qualified-version.sh)"
# Look up corresponding LOGSTASH_RELEASE_TRACK from versions.yml
LOGSTASH_RELEASE_TRACK=$(ruby -ryaml -e "puts YAML.load_file('versions.yml')['logstash-release-track']")
# Use logstash stream to find the corresponding stack verstion from logstash-versions.yml
STACK_VERSION=$(ruby -ryaml -ropen-uri -e "puts YAML.load(URI.open('https://raw.githubusercontent.com/logstash-plugins/.ci/1.x/logstash-versions.yml'))['snapshots']['${LOGSTASH_RELEASE_TRACK}']")
export ELASTICSEARCH_IMAGE_VERSION="${ELASTICSEARCH_IMAGE_VERSION:-$STACK_VERSION}"
export FILEBEAT_IMAGE_VERSION="${FILEBEAT_IMAGE_VERSION:-$STACK_VERSION}"

./gradlew --stacktrace artifactDockerObservabilitySRE -PfedrampHighMode=true

docker run docker.elastic.co/logstash/logstash-observability-sre:${QUALIFIED_VERSION} \
  logstash -e 'input { generator { count => 3 } } output { stdout { codec => rubydebug } }'

docker tag docker.elastic.co/logstash/logstash-observability-sre:${QUALIFIED_VERSION} pr-built-observability-sre-image

./gradlew observabilitySREsmokeTests --stacktrace