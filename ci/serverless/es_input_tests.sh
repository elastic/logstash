#!/usr/bin/env bash
set -ex

source ./$(dirname "$0")/common.sh

check_es_input() {
  check_logstash_api '.pipelines.main.plugins.inputs[0].events.out' '1'
}

check_plugin() {
  add_check check_es_input "Failed es-input check."
}

setup
index_test_data
run_logstash "$CURRENT_DIR/pipeline/003_es-input.conf" check_plugin
