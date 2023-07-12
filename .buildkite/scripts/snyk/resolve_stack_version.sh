#!/bin/bash

# This script resolves latest version from VERSION_URL SNAPSHOTS based on given N.x (where N is a precise, ex 8.x)
# Why Snapshot? - the 7.latest and 8.latest branchs will be accurately places in snapshots, not in releases.
# Ensure you have set the ELASTIC_STACK_VERSION environment variable.

set -e

VERSION_URL="https://raw.githubusercontent.com/elastic/logstash/main/ci/logstash_releases.json"

echo "Fetching versions from $VERSION_URL"
VERSIONS=$(curl --silent $VERSION_URL)
SNAPSHOT_KEYS=$(echo "$VERSIONS" | jq -r '.snapshots | .[]')

SNAPSHOT_VERSIONS=()
while IFS= read -r line; do
  SNAPSHOT_VERSIONS+=("$line")
  echo "Resolved snapshot version: $line"
done <<< "$SNAPSHOT_KEYS"