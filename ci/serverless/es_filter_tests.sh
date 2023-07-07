#!/usr/bin/env bash
set -ex

source ./$(dirname "$0")/common.sh

check_es_filter() {
  PLUGIN_CHECK=$(check_logstash_api '.pipelines.main.plugins.filters[] | select(.id == "ok") | .events.out' '1')
  PLUGIN_CHECK="${PLUGIN_CHECK: -1}"

  append_err_msg "$PLUGIN_CHECK" "Failed es-filter check."
  CHECKS+=("$PLUGIN_CHECK")
}

prepare_test_data
run_logstash "$CURRENT_DIR/pipeline/002_es-filter.conf" check_es_filter

trap clean_up_and_check EXIT