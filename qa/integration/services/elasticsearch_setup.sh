#!/bin/bash
set -ex
current_dir="$(dirname "$0")"
source "${current_dir}/helpers.sh"

if [ -n "${ES_VERSION+1}" ]; then
  echo "Elasticsearch version is $ES_VERSION"
  version=$ES_VERSION
else
   version=5.0.0-alpha5
fi

setup_es $version
start_es
