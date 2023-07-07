#!/usr/bin/env bash
set -ex

source ./$(dirname "$0")/common.sh

get_monitor_count() {
  curl -s -u "$ES_USER:$ES_PW" "$ES_ENDPOINT/.monitoring-logstash-*/_count" | jq '.count'
}

compare_monitor_count() {
  count=60
  while ! [[ $(get_monitor_count) -gt "$INITIAL_MONITOR_CNT" ]] && [[ $count -gt 0 ]]; do
      count=$(( count - 1 ))
      sleep 1
  done

  [[ $count -eq 0 ]] && echo "1" && return

  echo "Passed check"
  echo "0"
}

check_monitor() {
  MONITOR_CHECK=$(compare_monitor_count)
  MONITOR_CHECK="${MONITOR_CHECK: -1}"

  append_err_msg "$MONITOR_CHECK" "Failed monitor check."
  CHECKS+=("$MONITOR_CHECK")
}

export INITIAL_MONITOR_CNT=$(get_monitor_count)
run_cpm_logstash check_monitor

trap clean_up_and_check EXIT
