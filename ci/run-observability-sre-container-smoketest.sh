#!/bin/bash

source .buildkite/scripts/common/vm-agent.sh
./gradlew --stacktrace artifactDockerObservabilitySRE
logstash_version="$(awk -F':' '{ if ("logstash" == $1) { gsub(/ /,"",$2); print $2; exit } }' versions.yml)-SNAPSHOT"
docker run docker.elastic.co/logstash/logstash-observability-sre:${logstash_version} logstash -e 'input { generator { count => 3 } } output { stdout { codec => rubydebug } }'