#!/bin/bash
# Cleans up stale Snyk projects created by the Logstash artifact scan pipeline.
# Fetches active versions from logstash-versions.yml and deletes Snyk projects
# whose version is no longer tracked.
# Uses the same Vault credentials as scan-artifact.sh.

set -euo pipefail

source .buildkite/scripts/common/vm-agent.sh

echo "--- Retrieving Snyk token from Vault"
export SNYK_TOKEN=$(vault read -field=token secret/ci/elastic-logstash/snyk-creds)

echo "--- Running stale project cleanup"
python3 .buildkite/scripts/snyk/cleanup-stale-projects/cleanup.py
