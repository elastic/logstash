#!/bin/bash

set -e

QUALIFIED_VERSION="$(.buildkite/scripts/common/qualified-version.sh)"
# Look up corresponding LOSTASH_STREAM to test against. MAKE SURE TO UDPATE this per branch for example the 9.2 branch in logstash would
# correspond to the '9.current' key in the logstash-versions.yml file
LOGSTASH_STREAM=main
STACK_VERSION=$(ruby -ryaml -ropen-uri -e "puts YAML.load(URI.open('https://raw.githubusercontent.com/logstash-plugins/.ci/1.x/logstash-versions.yml'))['snapshots']['${LOGSTASH_STREAM}']")
export ELASTICSEARCH_IMAGE_VERSION="${ELASTICSEARCH_IMAGE_VERSION:-$STACK_VERSION}"
export FILEBEAT_IMAGE_VERSION="${FILEBEAT_IMAGE_VERSION:-$STACK_VERSION}"

./gradlew --stacktrace artifactDockerObservabilitySRE -PfedrampHighMode=true

docker run docker.elastic.co/logstash/logstash-observability-sre:${QUALIFIED_VERSION} \
  logstash -e 'input { generator { count => 3 } } output { stdout { codec => rubydebug } }'

docker tag docker.elastic.co/logstash/logstash-observability-sre:${QUALIFIED_VERSION} pr-built-observability-sre-image

./gradlew observabilitySREsmokeTests --stacktrace