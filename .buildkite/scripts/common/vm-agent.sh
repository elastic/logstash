#!/usr/bin/env bash

# ********************************************************
# This file contains prerequisite bootstrap invocations
# required for Logstash CI when using VM/baremetal agents
# ********************************************************

set -euo pipefail

export PATH="/opt/buildkite-agent/.rbenv/bin:/opt/buildkite-agent/.pyenv/bin:$PATH"
eval "$(rbenv init -)"
