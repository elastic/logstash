#!/usr/bin/env bash
set -eo pipefail

# *******************************************************
# Run benchmark for versions that have flow metrics
# Usage:
#   nohup bash -x all.sh > log.log 2>&1 &
# Accept env vars:
#   STACK_VERSIONS=8.15.0,8.15.1,8.16.0-SNAPSHOT # versions to test. It is comma separator string
# *******************************************************

IFS=','
STACK_VERSIONS="${STACK_VERSIONS:-8.6.0,8.7.0,8.8.0,8.9.0,8.10.0,8.11.0,8.12.0,8.13.0,8.14.0,8.15.0}"
read -ra STACK_VERSIONS <<< "$STACK_VERSIONS"

for V in "${STACK_VERSIONS[@]}" ; do
  LS_VERSION="$V" "main.sh"
done