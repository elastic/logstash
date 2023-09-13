#!/usr/bin/env bash
set -ex

export CURRENT_DIR="$(dirname "$0")"
export INDEX_NAME="serverless_it_${BUILDKITE_BUILD_NUMBER:-`date +%s`}"
# store all error messages
export ERR_MSGS=()
# numeric values representing the results of the checks. 0: pass, >0: fail
export CHECKS=()

setup_vault() {
  vault_path=secret/ci/elastic-logstash/serverless-test
  set +x
  export ES_ENDPOINT=$(vault read -field=es_host "${vault_path}")
  export ES_USER=$(vault read -field=es_superuser "${vault_path}") # dlq test
  export ES_PW=$(vault read -field=es_superuser_pw "${vault_path}")
  export KB_ENDPOINT=$(vault read -field=kb_host "${vault_path}")
  export MB_API_KEY=$(vault read -field=mb_api_key "${vault_path}")
  export PLUGIN_API_KEY=$(vault read -field=plugin_api_key "${vault_path}")
  export INTEGRATION_API_KEY_ENCODED=$(vault read -field=integration_api_key_encoded "${vault_path}")
  export TESTER_API_KEY_ENCODED=$(vault read -field=tester_api_key_encoded "${vault_path}")
  export CPM_API_KEY=$(vault read -field=cpm_api_key "${vault_path}")
  set -x
}

build_logstash() {
  ./gradlew clean bootstrap assemble installDefaultGems
}

index_test_data() {
  curl -X POST -H "Authorization: ApiKey $TESTER_API_KEY_ENCODED" "$ES_ENDPOINT/$INDEX_NAME/_bulk" -H 'Content-Type: application/json' --data-binary @"$CURRENT_DIR/test_data/book.json"
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


# $1: number of try
# $n: check function with args - return non empty string as pass
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


check_logstash_readiness() {
  curl_logstash() {
    [[ $(curl --silent localhost:9600) ]] && echo "0"
  }
  check_readiness() {
    count_down_check 120 curl_logstash
  }
  add_check check_readiness "Failed readiness check."

  [[ "${CHECKS[*]: -1}" -eq "1" ]] && exit 1

  echo "Logstash is Up !"
  return 0
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

# add check result to CHECKS
# $1: check function - expected the last char of result to be 0 or positive number
# $2: err msg
add_check() {
  FEATURE_CHECK=$($1)
  FEATURE_CHECK="${FEATURE_CHECK: -1}"

  ERR_MSGS+=("$2")
  CHECKS+=("$FEATURE_CHECK")
}

# check log if the line contains [ERROR] or [FATAL] and does not relate to "unreachable"
check_err_log() {
  LOG_FILE="$CURRENT_DIR/../../logs/logstash-plain.log"
  LOG_CHECK=$(grep -E "\[ERROR\]|\[FATAL\]" "$LOG_FILE" | grep -cvE "unreachable|Connection refused") || true

  ERR_MSGS+=("Found error in log")
  CHECKS+=("$LOG_CHECK")
}

# if CHECKS[i] is 1, print ERR_MSGS[i]
print_result() {
  for i in "${!CHECKS[@]}"; do
    [[ "${CHECKS[$i]}" -gt 0 ]] && echo "${ERR_MSGS[$i]}" || true
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
setup() {
  setup_vault
  build_logstash
  trap clean_up_and_get_result INT TERM EXIT
}
