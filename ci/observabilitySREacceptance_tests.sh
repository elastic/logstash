#!/bin/bash

set -e

# Look up corresponding LOSTASH_STREAM to test against. MAKE SURE TO UDPATE this per branch for example the 9.2 branch in logstash would
# correspond to the '9.current' key in the logstash-versions.yml file
LOGSTASH_STREAM=main
STACK_VERSION=$(ruby -ryaml -ropen-uri -e "puts YAML.load(URI.open('https://raw.githubusercontent.com/logstash-plugins/.ci/1.x/logstash-versions.yml'))['snapshots']['${LOGSTASH_STREAM}']")
export OBSERVABILITY_SRE_IMAGE_VERSION="${OBSERVABILITY_SRE_IMAGE_VERSION:-$STACK_VERSION}"
export ELASTICSEARCH_IMAGE_VERSION="${ELASTICSEARCH_IMAGE_VERSION:-$STACK_VERSION}"
export FILEBEAT_IMAGE_VERSION="${FILEBEAT_IMAGE_VERSION:-$STACK_VERSION}"

./gradlew observabilitySREacceptanceTests --stacktrace
