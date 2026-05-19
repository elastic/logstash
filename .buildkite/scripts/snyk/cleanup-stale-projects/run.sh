#!/bin/bash
# Cleans up stale Snyk projects created by the Logstash artifact scan pipeline.
# Uses the same Vault credentials as scan-artifact.sh.
# Usage: ./run.sh <deactivate|delete>

set -euo pipefail

ACTION="${1:?Usage: $0 <deactivate|delete>}"

source .buildkite/scripts/common/vm-agent.sh

echo "--- Retrieving Snyk token from Vault"
export SNYK_TOKEN=$(vault read -field=token secret/ci/elastic-logstash/snyk-creds)

echo "--- Running stale project cleanup (action: ${ACTION})"
python3 .buildkite/scripts/snyk/cleanup-stale-projects/cleanup.py --action "${ACTION}"
