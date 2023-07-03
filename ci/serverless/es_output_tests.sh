#!/usr/bin/env bash
set -ex

source ./$(dirname "$0")/common.sh

setup_vault
build_logstash

# test
check_es_output() {
  PLUGIN_ES_OUTPUT=$(check_logstash_api '.pipelines.main.plugins.outputs[0].documents.successes' '1')
  export PLUGIN_ES_OUTPUT="${PLUGIN_ES_OUTPUT: -1}"
}

run_logstash "$CURRENT_DIR/pipeline/001_es-output.conf" check_es_output

trap clean_up EXIT
exit $PLUGIN_ES_OUTPUT