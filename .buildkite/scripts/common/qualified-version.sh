#!/usr/bin/env bash

# ********************************************************
# Source this script to get the QUALIFIED_VERSION env var
# or execute it to receive the qualified version on stdout
# ********************************************************

set -euo pipefail

export QUALIFIED_VERSION="$(
  # Extract the version number from the version.yml file
  # e.g.: 8.6.0
  printf '%s' "$(awk -F':' '{ if ("logstash" == $1) { gsub(/^ | $/,"",$2); printf $2; exit } }' versions.yml)"

  # Qualifier is passed from CI as optional field and specify the version postfix
  # in case of alpha or beta releases for staging builds only:
  # e.g: 8.0.0-alpha1
  printf '%s' "${VERSION_QUALIFIER:+-${VERSION_QUALIFIER}}"

  # Include git SHA if requested
  if [[ -n "${INCLUDE_COMMIT_ID:+x}" ]]; then
    printf '%s' "-$(git rev-parse --short HEAD)"
  fi

  # add the SNAPSHOT tag unless WORKFLOW_TYPE=="staging" or RELEASE=="1"
  if [[ ! ( "${WORKFLOW_TYPE:-}" == "staging" || "${RELEASE:+$RELEASE}" == "1" ) ]]; then
    printf '%s' "-SNAPSHOT"
  fi
)"

# if invoked directly, output the QUALIFIED_VERSION to stdout
if [[ "$0" == "${BASH_SOURCE:-${ZSH_SCRIPT:-}}" ]]; then
  printf '%s' "${QUALIFIED_VERSION}"
fi
