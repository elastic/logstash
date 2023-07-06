#!/usr/bin/env bash
set -ex

export CURRENT_DIR="$(dirname "$0")"
export INDEX_NAME="serverless_it_${BUILDKITE_BUILD_NUMBER:-`date +%s`}"
export ERR_MSG=()

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

bulk_index_data() {
  curl -X POST -u "$ES_USER:$ES_PW" "$ES_ENDPOINT/$INDEX_NAME/_bulk" -H 'Content-Type: application/json' --data-binary @"$CURRENT_DIR/test_data/book.json"
}



# $1: function for checking result
# run_cpm_logstash check
run_cpm_logstash() {
  # copy log4j
  cp  "$CURRENT_DIR/../../config/log4j2.properties" "$CURRENT_DIR/config/log4j2.properties"

  # run logstash
  $CURRENT_DIR/../../bin/logstash --path.settings "$CURRENT_DIR/config" 2>/dev/null &
  export LS_PID=$!

  check_logstash_readiness

  $1 # check result
  kill $LS_PID
}

# $1: pipeline file
# $2: function for checking result
# run_logstash 001_es-output.conf check_es_output
run_logstash() {
  $CURRENT_DIR/../../bin/logstash -f "$1" 2>/dev/null &
  export LS_PID=$!

  check_logstash_readiness

  $2 # check result

  print_result

  kill $LS_PID
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

check_logstash_api() {
  count=60
  echo "Checking Logstash API..."
  while ! [[ $(curl --silent localhost:9600/_node/stats | jq "$1") -ge $2 ]] && [[ $count -gt 0 ]]; do
      count=$(( count - 1 ))
      sleep 1
  done

  [[ $count -eq 0 ]] && echo "1" && return

  echo "Passed check! jq $1"
  echo "0"
}

print_result() {
  for msg in "${ERR_MSG[@]}"; do
    echo "$msg"
  done
}

clean_up() {
  exit_code=$?
  kill $LS_PID
  exit $exit_code
}