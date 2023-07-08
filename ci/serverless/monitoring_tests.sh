#!/usr/bin/env bash
set -ex

source ./$(dirname "$0")/common.sh

get_monitor_count() {
  curl -s -u "$ES_USER:$ES_PW" "$ES_ENDPOINT/.monitoring-logstash-*/_count" | jq '.count'
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

export INITIAL_MONITOR_CNT=$(get_monitor_count)
run_cpm_logstash check
