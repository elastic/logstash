#!/usr/bin/env bash

# *********************************************************
# This file provides the qualified version, considering the
# contents of /versions.yml, VERSION_QUALIFIER, and RELEASE
# *********************************************************

set -euo pipefail

export QUALIFIED_VERSION="$(
  # extract logstash version from versions.yml
  printf "$(awk -F':' '{ if ("logstash" == $1) { gsub(/^ | $/,"",$2); printf $2; exit } }' versions.yml)"

  # append the VERSION_QUALIFIER if it is present
  printf "${VERSION_QUALIFIER:+-${VERSION_QUALIFIER}}"

  # add the SNAPSHOT tag unless RELEASE=1
  [[ "${RELEASE:-0}" == "1" ]] || printf "-SNAPSHOT"
)"

if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
  printf "${QUALIFIED_VERSION}"
fi