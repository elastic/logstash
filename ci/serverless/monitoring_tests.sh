#!/usr/bin/env bash

# Legacy monitoring is disabled. Serverless does not support /_monitoring/bulk, hence this test always fails to ingest metrics.
set -ex

source ./$(dirname "$0")/common.sh

get_monitor_count() {
  curl -s -H "Authorization: ApiKey $LS_ROLE_API_KEY_ENCODED" "$ES_ENDPOINT/.monitoring-logstash-7-*/_count" | jq '.count'
}

compare_monitor_count() {
   [[ $(get_monitor_count) -gt "$INITIAL_MONITOR_CNT" ]] && echo "0"
}

check_monitor() {
  count_down_check 20 compare_monitor_count
}

check() {
  add_check check_monitor "Failed monitor check."
}

setup
export INITIAL_MONITOR_CNT=$(get_monitor_count)
run_cpm_logstash check
