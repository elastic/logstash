#!/usr/bin/env bash
set -ex

source ./$(dirname "$0")/common.sh

check_es_filter() {
  check_logstash_api '.pipelines.main.plugins.filters[] | select(.id == "ok") | .events.out' '1'
}

check_plugin() {
  add_check check_es_filter "Failed es-filter check."
}

setup
index_test_data
run_logstash "$CURRENT_DIR/pipeline/002_es-filter.conf" check_plugin
