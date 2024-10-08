#!/usr/bin/env bash
set -eo pipefail

python3 -mpip install -r .buildkite/scripts/health-report-tests/requirements.txt
python3 .buildkite/scripts/health-report-tests/main.py
