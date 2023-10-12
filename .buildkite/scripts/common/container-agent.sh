#!/usr/bin/env bash

# ********************************************************
# This file contains prerequisite bootstrap invocations
# required for Logstash CI when using containerized agents
# ********************************************************

set -euo pipefail

export PATH="/usr/local/rbenv/bin:$PATH"
eval "$(rbenv init -)"
