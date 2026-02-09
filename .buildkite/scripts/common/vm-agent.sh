#!/usr/bin/env bash

# ********************************************************
# This file contains prerequisite bootstrap invocations
# required for Logstash CI when using VM/baremetal agents
# ********************************************************

set -euo pipefail

source .ci/java-versions.properties
export JAVA_HOME="/opt/buildkite-agent/.java/$LS_BUILD_JAVA"
export PATH="/opt/buildkite-agent/.rbenv/bin:/opt/buildkite-agent/.pyenv/bin:$JAVA_HOME/bin:$PATH"
eval "$(rbenv init -)"
