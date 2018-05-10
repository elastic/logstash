#!/bin/bash
export JRUBY_OPTS="-J-Xmx1g"
export GRADLE_OPTS="-Xmx2g -Dorg.gradle.daemon=false -Dorg.gradle.logging.level=info"

ci/docker_run.sh logstash-license-check ci/license_check.sh -m 4G
