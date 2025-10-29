#!/bin/bash

set -e

# Look up corresponding LOGSTASH_STREAM from versions.yml
LOGSTASH_STREAM=$(ruby -ryaml -e "puts YAML.load_file('versions.yml')['logstash-stream']")
# Use logstash stream to find the corresponding stack verstion from logstash-versions.yml
STACK_VERSION=$(ruby -ryaml -ropen-uri -e "puts YAML.load(URI.open('https://raw.githubusercontent.com/logstash-plugins/.ci/1.x/logstash-versions.yml'))['snapshots']['${LOGSTASH_STREAM}']")
export OBSERVABILITY_SRE_IMAGE_VERSION="${OBSERVABILITY_SRE_IMAGE_VERSION:-$STACK_VERSION}"
export ELASTICSEARCH_IMAGE_VERSION="${ELASTICSEARCH_IMAGE_VERSION:-$STACK_VERSION}"
export FILEBEAT_IMAGE_VERSION="${FILEBEAT_IMAGE_VERSION:-$STACK_VERSION}"

./gradlew observabilitySREacceptanceTests --stacktrace
