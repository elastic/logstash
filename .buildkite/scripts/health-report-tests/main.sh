#!/bin/bash

set -euo pipefail

export PATH="/opt/buildkite-agent/.rbenv/bin:/opt/buildkite-agent/.pyenv/bin:/opt/buildkite-agent/.java/bin:$PATH"
export JAVA_HOME="/opt/buildkite-agent/.java"
export PYENV_VERSION="3.11.5"

eval "$(rbenv init -)"
eval "$(pyenv init -)"

echo "--- Installing dependencies"
python3 -m pip install -r .buildkite/scripts/health-report-tests/requirements.txt

echo "--- Running tests"
python3 .buildkite/scripts/health-report-tests/main.py