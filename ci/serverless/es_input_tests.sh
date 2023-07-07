#!/usr/bin/env bash
set -ex

source ./$(dirname "$0")/common.sh

check_es_input() {
  PLUGIN_CHECK=$(check_logstash_api '.pipelines.main.plugins.inputs[0].events.out' '1')
  PLUGIN_CHECK="${PLUGIN_CHECK: -1}"

  append_err_msg "$PLUGIN_CHECK" "Failed es-input check."
  CHECKS+=("$PLUGIN_CHECK")
}

prepare_test_data
run_logstash "$CURRENT_DIR/pipeline/003_es-input.conf" check_es_input

trap clean_up_and_check EXIT