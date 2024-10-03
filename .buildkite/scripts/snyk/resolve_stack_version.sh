#!/bin/bash

# This script resolves latest version from VERSION_URL SNAPSHOTS based on given N.x (where N is a precise, ex 8.x)
# Why Snapshot? - the 7.latest and 8.latest branchs will be accurately places in snapshots, not in releases.
# Ensure you have set the ELASTIC_STACK_VERSION environment variable.

set -e

VERSION_URL="https://raw.githubusercontent.com/elastic/logstash/main/ci/branches.json"

echo "Fetching versions from $VERSION_URL"
VERSIONS=$(curl --silent $VERSION_URL)
TARGET_BRANCHES=$(echo "$VERSIONS" | jq -r '.branches | map(.branch) | join(" ")')
TARGET_BRANCHES=($TARGET_BRANCHES)
