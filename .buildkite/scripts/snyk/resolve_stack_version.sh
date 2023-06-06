#!/bin/bash

# This script resolves latest version from VERSION_URL SNAPSHOTS based on given N.x (where N is a precise, ex 8.x)
# Why Snapshot? - the 7.latest and 8.latest branchs will be accurately places in snapshots, not in releases.
# Ensure you have set the ELASTIC_STACK_VERSION environment variable.

set -e

VERSION_URL="https://raw.githubusercontent.com/elastic/logstash/main/ci/logstash_releases.json"

if [ "$ELASTIC_STACK_VERSION" ]; then
    echo "Fetching versions from $VERSION_URL"
    VERSIONS=$(curl --silent $VERSION_URL)
    ELASTIC_STACK_RETRIEVED_VERSION=$(echo $VERSIONS | jq '.snapshots."'"$ELASTIC_STACK_VERSION"'"')
    if [[ "$ELASTIC_STACK_RETRIEVED_VERSION" != "null" ]]; then
      # remove starting and trailing double quotes
      ELASTIC_STACK_RETRIEVED_VERSION="${ELASTIC_STACK_RETRIEVED_VERSION%\"}"
      ELASTIC_STACK_RETRIEVED_VERSION="${ELASTIC_STACK_RETRIEVED_VERSION#\"}"
      echo "Translated $ELASTIC_STACK_VERSION to ${ELASTIC_STACK_RETRIEVED_VERSION}"
      export ELASTIC_STACK_VERSION=$ELASTIC_STACK_RETRIEVED_VERSION
    fi

    echo "Using $ELASTIC_STACK_VERSION version."
else
    echo "Please set the ELASTIC_STACK_VERSION environment variable"
    echo "For example: export ELASTIC_STACK_VERSION=8.x"
    echo "OR export ELASTIC_STACK_VERSION=main"
    exit 1
fi
