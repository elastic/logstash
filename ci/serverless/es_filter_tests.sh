#!/usr/bin/env bash
set -ex

source ./$(dirname "$0")/common.sh

setup_vault
build_logstash

# test
check_es_filter() {
  PLUGIN_ES_FILTER=$(check_logstash_api '.pipelines.main.plugins.filters[] | select(.id == "ok") | .events.out' '1')
  export PLUGIN_ES_FILTER="${PLUGIN_ES_FILTER: -1}"
}

bulk_index_data
run_logstash "$CURRENT_DIR/pipeline/002_es-filter.conf" check_es_filter

trap clean_up EXIT
exit $PLUGIN_ES_FILTER