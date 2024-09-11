#!/usr/bin/env bash
set -eo pipefail

# *******************************************************
# Run benchmark for all versions that have flow metrics
# Usage:
#   nohup bash -x all.sh > log.log 2>&1 &
# Accept env vars:
#   VERSIONS=8.15.0,8.15.1,8.16.0-SNAPSHOT # versions to test with comma separator
# *******************************************************

IFS=','
VERSIONS="${VERSIONS:-8.6.0,8.7.0,8.8.0,8.9.0,8.10.0,8.11.0,8.12.0,8.13.0,8.14.0,8.15.0}"
read -ra VERSIONS <<< "$VERSIONS"

for V in "${VERSIONS[@]}" ; do
  LS_VERSION="$V" VERSIONS="2,4" "main.sh" 4 memory
done