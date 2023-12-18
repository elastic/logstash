#!/usr/bin/env bash

# **************************************************************
# This file contains prerequisite bootstrap invocations
# required for Logstash CI when using custom multi-jdk VM images
# It is primarily used by the exhaustive BK pipeline.
# **************************************************************

set -euo pipefail

# the convoluted AWK script below grabs the major version from bundled_jdk:\nrevision in Logstash's `version.yml`
# we don't use yq (or e.g. the yaml Python module) because both aren't guaranteed to be pre-installed on all VMs.
_JAVA_MAJOR_VERSION=$(awk '/^bundled_jdk:/ {found_bundled_jdk=1; next} found_bundled_jdk && /^[\ \t]*revision:/ {print $0}' versions.yml | awk -F ': ' '{print $2}' | cut -d '.' -f 1,1)

export JAVA_HOME="/opt/buildkite-agent/.java/adoptiumjdk_${_JAVA_MAJOR_VERSION}"
export PATH="/opt/buildkite-agent/.rbenv/bin:/opt/buildkite-agent/.pyenv/bin:${JAVA_HOME}/bin:$PATH"

eval "$(rbenv init -)"
