#!/usr/bin/env bash

# **************************************************************
# This file contains prerequisite bootstrap invocations
# required for Logstash CI when using custom multi-jdk VM images
# It is primarily used by the exhaustive BK pipeline.
# **************************************************************

set -euo pipefail

source .ci/java-versions.properties
export BUILD_JAVA_HOME=/opt/buildkite-agent/.java/$LS_BUILD_JAVA

export PATH="/opt/buildkite-agent/.rbenv/bin:/opt/buildkite-agent/.pyenv/bin:$BUILD_JAVA_HOME/bin:$PATH"

eval "$(rbenv init -)"
