#!/usr/bin/env bash
set -ex

source ./$(dirname "$0")/common.sh

get_cpu_arch() {
  local arch=$(uname -m)

  if [ "$arch" == "arm64" ]; then
    echo "aarch64"
  else
    echo "$arch"
  fi
}

export INDEX_NAME=".monitoring-logstash-8-mb"
export OS=$(uname -s | tr '[:upper:]' '[:lower:]')
export ARCH=$(get_cpu_arch)
export BEATS_VERSION=$(curl -s "https://api.github.com/repos/elastic/beats/tags" | jq -r '.[0].name' | cut -c 2-)

start_metricbeat() {
  cd "$CURRENT_DIR"

  MB_FILENAME="metricbeat-$BEATS_VERSION-$OS-$ARCH"
  MB_DL_URL="https://artifacts.elastic.co/downloads/beats/metricbeat/$MB_FILENAME.tar.gz"

  if [[ ! -d "$MB_FILENAME" ]]; then
      curl -o "$MB_FILENAME.tar.gz" "$MB_DL_URL"
      tar -zxf "$MB_FILENAME.tar.gz"
  fi

  chmod go-w "metricbeat/metricbeat.yml"
  "$MB_FILENAME/metricbeat" -c "metricbeat/metricbeat.yml" &
  export MB_PID=$!
  cd -
}

stop_metricbeat() {
   [[ -n "$MB_PID" ]] && kill "$MB_PID" || true
}

get_monitor_count() {
  curl -s -H "Authorization: ApiKey $TESTER_API_KEY_ENCODED" "$ES_ENDPOINT/$INDEX_NAME/_count" | jq '.count // 0'
}

compare_monitor_count() {
  [[ $(get_monitor_count) -gt "$INITIAL_MONITOR_CNT" ]] && echo "0"
}

check_monitor_output() {
  count_down_check 60 compare_monitor_count
}

check_plugin() {
  add_check check_monitor_output "Failed metricbeat monitor check."
}

metricbeat_clean_up() {
  exit_code=$?
  ERR_MSGS+=("Unknown error!")
  CHECKS+=("$exit_code")

  stop_metricbeat

  clean_up_and_get_result
}

setup
trap metricbeat_clean_up INT TERM EXIT
export INITIAL_MONITOR_CNT=$(get_monitor_count)

start_metricbeat
run_logstash "$CURRENT_DIR/pipeline/005_uptime.conf" check_plugin
