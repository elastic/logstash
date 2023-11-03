#!/usr/bin/env bash

# ********************************************************
# This file contains prerequisite bootstrap invocations
# required for Logstash CI JDK matrix tests
# ********************************************************

set -euo pipefail

JDK=$1

# unset generic JAVA_HOME
unset JAVA_HOME

# LS env vars for JDK matrix tests
export JAVA_CUSTOM_DIR="/opt/buildkite-agent/.java/$JDK"
export BUILD_JAVA_HOME=$JAVA_CUSTOM_DIR
export RUNTIME_JAVA_HOME=$JAVA_CUSTOM_DIR
export LS_JAVA_HOME=$JAVA_CUSTOM_DIR

export PATH="/opt/buildkite-agent/.rbenv/bin:/opt/buildkite-agent/.pyenv/bin:$PATH"
eval "$(rbenv init -)"
