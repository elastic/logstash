#!/usr/bin/env bash

# ********************************************************
# This file contains prerequisite bootstrap invocations
# required for Logstash CI when using containerized agents
# ********************************************************

set -euo pipefail

if [[ $(whoami) == "logstash" ]]
then
    export PATH="/home/logstash/.rbenv/bin:$PATH"
    eval "$(rbenv init -)"
else
    export PATH="/usr/local/rbenv/bin:$PATH"
    eval "$(rbenv init -)"
fi
if ! command -v git >/dev/null 2>&1; then
   echo "GIT_CHECK_ERROR: git command not found in PATH" >&2
   exit 1
fi

git_version=$(git --version)
if [ $? -ne 0 ]; then
   echo "GIT_CHECK_ERROR: git installation appears broken" >&2 
   exit 1
fi

echo "GIT_CHECK_SUCCESS: Found $git_version"