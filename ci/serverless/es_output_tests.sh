#!/usr/bin/env bash
set -ex

source ./$(dirname "$0")/common.sh

check_es_output() {
  PLUGIN_CHECK=$(check_logstash_api '.pipelines.main.plugins.outputs[0].documents.successes' '1')
  PLUGIN_CHECK="${PLUGIN_CHECK: -1}"

  append_err_msg "$PLUGIN_CHECK" "Failed es-output check."
  CHECKS+=("$PLUGIN_CHECK")
}

run_logstash "$CURRENT_DIR/pipeline/001_es-output.conf" check_es_output

trap clean_up_and_check EXIT