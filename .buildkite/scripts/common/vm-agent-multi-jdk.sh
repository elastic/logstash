#!/usr/bin/env bash

# **************************************************************
# This file contains prerequisite bootstrap invocations
# required for Logstash CI when using custom multi-jdk VM images
# It is primarily used by the exhaustive BK pipeline.
# **************************************************************

set -euo pipefail

export PATH="/opt/buildkite-agent/.rbenv/bin:/opt/buildkite-agent/.pyenv/bin:/opt/buildkite-agent/.java/bin:$PATH"

# the convoluted AWK script below grabs the major version from bundled_jdk:\nrevision in Logstash's `version.yml`
# we don't use yq (or e.g. the yaml Python module) because both aren't guaranteed to be pre-installed on all VMs.
_JAVA_MAJOR_VERSION=$(awk '/^bundled_jdk:/ {found_bundled_jdk=1; next} found_bundled_jdk && /^[[:space:]]*revision:/ {gsub(/^[[:space:]]*revision:[[:space:]]*/, ""); split($1, rev, "."); print rev[1]; found_bundled_jdk=0}' versions.yml)

export JAVA_HOME="/opt/buildkite-agent/adoptiumjdk_${_JAVA_MAJOR_VERSION}"
eval "$(rbenv init -)"
