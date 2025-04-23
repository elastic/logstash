#!/usr/bin/env bash
set -eo pipefail

# *******************************************************
# Run benchmark for versions that have flow metrics
# When the hardware changes, run the marathon task to establish a new baseline.
# Usage:
#   nohup bash -x all.sh > log.log 2>&1 &
# Accept env vars:
#   STACK_VERSIONS=8.15.0,8.15.1,8.16.0-SNAPSHOT # versions to test. It is comma separator string
# *******************************************************

SCRIPT_PATH="$(dirname "${BASH_SOURCE[0]}")"
source "$SCRIPT_PATH/core.sh"

parse_stack_versions() {
  IFS=','
  STACK_VERSIONS="${STACK_VERSIONS:-8.9.0,8.10.0,8.11.0,8.12.0,8.13.0,8.14.0,8.15.5,8.16.6,8.17.5,8.18.0,9.0.0}"
  read -ra STACK_VERSIONS <<< "$STACK_VERSIONS"
}

main() {
  parse_stack_versions
  parse_args "$@"
  get_secret
  generate_logs
  check_logs

  USER_QTYPE="$QTYPE"

  for V in "${STACK_VERSIONS[@]}" ; do
    LS_VERSION="$V"
    QTYPE="$USER_QTYPE"
    pull_images
    create_directory
    if [[ $QTYPE == "all" ]]; then
      queue
    else
      worker
    fi
  done
}

main "$@"