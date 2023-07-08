#!/usr/bin/env bash
set -ex

source ./$(dirname "$0")/common.sh


check_named_index() {
  check_logstash_api '.pipelines.main.plugins.outputs[0].documents.successes' '1'
}

get_data_stream_count() {
  curl -s -u "$ES_USER:$ES_PW" "$ES_ENDPOINT/logs-generic-default/_count" | jq '.count'
}

compare_data_stream_count() {
  [[ $(get_data_stream_count) -ge "$INITIAL_DATA_STREAM_CNT" ]] && echo "0"
}

check_data_stream_output() {
  count_down_check 20 compare_data_stream_count
}

check_plugin() {
  add_check check_named_index "Failed es-output check."
  add_check check_data_stream_output "Failed data stream check."
}

export INITIAL_DATA_STREAM_CNT=$(get_data_stream_count)
run_logstash "$CURRENT_DIR/pipeline/001_es-output.conf" check_plugin