#!/usr/bin/env bash
set -ex

export CURRENT_DIR="$(dirname "$0")"
export INDEX_NAME="serverless_it_${BUILDKITE_BUILD_NUMBER:-`date +%s`}"
# error messages to print
export ERR_MSGS=()
# numeric values representing the results of the checks. 0: pass, >0: fail
export CHECKS=()

setup_vault() {
  vault_path=secret/ci/elastic-logstash/serverless-test
  set +x
  export ES_ENDPOINT=$(vault read -field=host "${vault_path}")
  export ES_USER=$(vault read -field=super_user "${vault_path}")
  export ES_PW=$(vault read -field=super_user_pw "${vault_path}")
  set -x
}

build_logstash() {
  ./gradlew clean bootstrap assemble installDefaultGems
}

prepare_test_data() {
  curl -X POST -u "$ES_USER:$ES_PW" "$ES_ENDPOINT/$INDEX_NAME/_bulk" -H 'Content-Type: application/json' --data-binary @"$CURRENT_DIR/test_data/book.json"
}

# $1: check function
run_cpm_logstash() {
  # copy log4j
  cp  "$CURRENT_DIR/../../config/log4j2.properties" "$CURRENT_DIR/config/log4j2.properties"

  # run logstash
  $CURRENT_DIR/../../bin/logstash --path.settings "$CURRENT_DIR/config" 2>/dev/null &
  export LS_PID=$!

  check_logstash_readiness

  $1 # check function

  kill "$LS_PID" || true
}

# $1: pipeline file
# $2: check function
# run_logstash 001_es-output.conf check_es_output
run_logstash() {
  $CURRENT_DIR/../../bin/logstash -f "$1" 2>/dev/null &
  export LS_PID=$!

  check_logstash_readiness

  $2 # check function

  kill "$LS_PID" || true
}

check_logstash_readiness() {
  count=120
  echo "Waiting Logstash to respond..."
  while ! [[ $(curl --silent localhost:9600) ]] && [[ $count -gt 0 ]]; do
      count=$(( count - 1 ))
      sleep 1
  done

  [[ $count -eq 0 ]] && exit 1

  echo "Logstash is Up !"
  return 0
}

# $1: number of try
# $n: check function with args
count_down_check() {
    count=$1
    while ! [[ $("${@:2}") ]] && [[ $count -gt 0 ]]; do
        count=$(( count - 1 ))
        sleep 1
    done

    [[ $count -eq 0 ]] && echo "1" && return

    echo "Passed check!"
    echo "0"
}

# $1: jq filter
# $2: expected value
# check_logstash_api '.pipelines.main.plugins.outputs[0].documents.successes' '1'
check_logstash_api() {
  curl_node_stats() {
    [[ $(curl --silent localhost:9600/_node/stats | jq "$1") -ge "$2" ]] && echo "0"
  }

  count_down_check 30 curl_node_stats "$1" "$2"
}

# append err msg if $1 is err
# $1: err code 0/1
# $2: err msg
add_msg_if_fail() {
  [[ "$1" -ge '1' ]] && ERR_MSGS+=("$2") || true
}

# add check result to CHECKS
# $1: function to check
# $2: err msg
add_check() {
  PLUGIN_CHECK=$($1)
  PLUGIN_CHECK="${PLUGIN_CHECK: -1}"

  add_msg_if_fail "$PLUGIN_CHECK" "$2"
  CHECKS+=("$PLUGIN_CHECK")
}

# check log if the line contains [ERROR] or [FATAL] and does not relate to "unreachable"
check_err_log() {
  LOG_FILE="$CURRENT_DIR/../../logs/logstash-plain.log"
  LOG_CHECK=$(grep -E "\[ERROR\]|\[FATAL\]" "$LOG_FILE" | grep -cv "unreachable") || true
  add_msg_if_fail "$LOG_CHECK" "Log contains error."
  CHECKS+=("$LOG_CHECK")
}

print_result() {
  for msg in "${ERR_MSGS[@]}"; do
    echo "$msg"
  done
}

# exit 1 if one of the checks fails
exit_with_code() {
  for c in "${CHECKS[@]}"; do
      [[ $c -gt 0 ]] && exit 1
  done

  exit 0
}

clean_up_and_get_result() {
  [[ -n "$LS_PID" ]] && kill "$LS_PID" || true

  check_err_log
  print_result
  exit_with_code
}

# common setup
setup_vault
build_logstash