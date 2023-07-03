#!/usr/bin/env bash
set -ex

source ./$(dirname "$0")/common.sh

setup_vault
build_logstash

# test
check_es_input() {
  PLUGIN_ES_INPUT=$(check_logstash_api '.pipelines.main.plugins.inputs[0].events.out' '1')
  export PLUGIN_ES_INPUT="${PLUGIN_ES_INPUT: -1}"
}

bulk_index_data
run_logstash "$CURRENT_DIR/pipeline/003_es-input.conf" check_es_input

trap clean_up EXIT
exit $PLUGIN_ES_INPUT