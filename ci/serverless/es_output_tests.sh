#!/usr/bin/env bash
set -ex

source ./$(dirname "$0")/common.sh


check_named_index() {
  check_logstash_api '.pipelines.main.plugins.outputs[] | select(.id == "named_index") | .documents.successes' '1'
}

get_data_stream_count() {
  curl -s -H "Authorization: ApiKey $TESTER_API_KEY_ENCODED" "$ES_ENDPOINT/logs-$INDEX_NAME.001-default/_count" | jq '.count // 0'
}

compare_data_stream_count() {
  [[ $(get_data_stream_count) -gt "$INITIAL_DATA_STREAM_CNT" ]] && echo "0"
}

check_data_stream_output() {
  count_down_check 20 compare_data_stream_count
}

check_plugin() {
  add_check check_named_index "Failed index check."
  add_check check_data_stream_output "Failed data stream check."
}

setup
export INITIAL_DATA_STREAM_CNT=$(get_data_stream_count)
run_logstash "$CURRENT_DIR/pipeline/001_es-output.conf" check_plugin