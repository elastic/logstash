#!/bin/bash

# This script resolves latest version from VERSION_URL SNAPSHOTS based on given N.x (where N is a precise, ex 8.x)
# Why Snapshot? - the 7.latest and 8.latest branchs will be accurately places in snapshots, not in releases.
# Ensure you have set the ELASTIC_STACK_VERSION environment variable.

set -e

VERSION_URL="https://raw.githubusercontent.com/elastic/logstash/main/ci/logstash_releases.json"

echo "Fetching versions from $VERSION_URL"
VERSIONS=$(curl --silent $VERSION_URL)
SNAPSHOTS=$(echo $VERSIONS | jq '.snapshots' | jq 'keys | .[]')
IFS=$'\n' read -d "\034" -r -a SNAPSHOT_KEYS <<<"${SNAPSHOTS}\034"

SNAPSHOT_VERSIONS=()
for KEY in "${SNAPSHOT_KEYS[@]}"
do
  # remove starting and trailing double quotes
  KEY="${KEY%\"}"
  KEY="${KEY#\"}"
  SNAPSHOT_VERSION=$(echo $VERSIONS | jq '.snapshots."'"$KEY"'"')
  echo "Resolved snapshot version: $SNAPSHOT_VERSION"
  SNAPSHOT_VERSIONS+=("$SNAPSHOT_VERSION")
done