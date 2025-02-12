#!/bin/bash

# This script resolves latest version from VERSION_URL SNAPSHOTS based on given N.x (where N is a precise, ex 8.x)
# Why Snapshot? - the 7.latest and 8.latest branchs will be accurately places in snapshots, not in releases.
# Ensure you have set the ELASTIC_STACK_VERSION environment variable.

set -e

VERSION_URL="https://storage.googleapis.com/artifacts-api/snapshots/branches.json"

echo "Fetching versions from $VERSION_URL"
readarray -t TARGET_BRANCHES < <(curl --retry-all-errors --retry 5 --retry-delay 5 -fsSL $VERSION_URL | jq -r '.branches[]')
echo "${TARGET_BRANCHES[@]}"

