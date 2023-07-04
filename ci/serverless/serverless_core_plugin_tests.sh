### require jq
#!/usr/bin/env bash
set -ex

CURRENT_DIR="$(dirname "$0")"

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

prepare_cpm_pipelines() {
  export INDEX_NAME="serverless_it_${BUILDKITE_BUILD_NUMBER:-`date +%s`}"

  # es-output
  index_pipeline 'gen_es' '{
    "pipeline": "input { generator { count => 100 } } output { elasticsearch { hosts => \"${ES_ENDPOINT}\" user => \"${ES_USER}\" password => \"${ES_PW}\" index=> \"'$INDEX_NAME'\" } }",
    "last_modified": "2022-02-22T22:22:22.222Z",
    "pipeline_metadata": { "version": "1"},
    "username": "log.stash",
    "pipeline_settings": {"pipeline.batch.delay": "50"}
  }'

  # # es-input
  # index_pipeline 'es_stdout' '{
  #   "pipeline": "input { elasticsearch { hosts => \"${ES_ENDPOINT}\" user => \"${ES_USER}\" password => \"${ES_PW}\" index => \"logs-generic-default\" schedule => \"*/10 * * * * *\" size => 100 } } output { stdout { codec => dots } }",
  #   "last_modified": "2022-02-22T22:22:22.222Z",
  #   "pipeline_metadata": { "version": "1"},
  #   "username": "log.stash",
  #   "pipeline_settings": {"pipeline.batch.delay": "50"}
  # }'

  # es-filter
  index_pipeline 'gen_es_stdout' '{
    "pipeline": "input { generator { count => 100 } } filter { elasticsearch { hosts => \"${ES_ENDPOINT}\" user => \"${ES_USER}\" password => \"${ES_PW}\" index => \"'$INDEX_NAME'\" query => \"*\" add_field => {\"passed\" => \"good\"} } if [passed] == \"good\" { mutate { add_tag => [\"yes\"] } }  } output { stdout { codec => dots } }",
    "last_modified": "2022-02-22T22:22:22.222Z",
    "pipeline_metadata": { "version": "1"},
    "username": "log.stash",
    "pipeline_settings": {"pipeline.batch.delay": "50"}
  }'
}

index_pipeline() {
  # index pipeline to serverless ES
  curl -X PUT -u "$ES_USER:$ES_PW" "$ES_ENDPOINT/_logstash/pipeline/$1"  -H 'Content-Type: application/json' -d "$2"; 

  #TODO check error
}

get_monitor_count() {
  curl -s -u "$ES_USER:$ES_PW" "$ES_ENDPOINT/.monitoring-logstash-*/_count" | jq '.count'
}

run_logstash() {
  # copy log4j
  cp  "$CURRENT_DIR/../../config/log4j2.properties" "$CURRENT_DIR/log4j2.properties"

  # create logstash.yml
  cat <<EOF > "$CURRENT_DIR/logstash.yml"
path.logs: $CURRENT_DIR
xpack.management.enabled: true
xpack.management.pipeline.id: ["*"]
xpack.management.elasticsearch.username: $ES_USER
xpack.management.elasticsearch.password: $ES_PW
xpack.management.elasticsearch.hosts: ["$ES_ENDPOINT"]

xpack.monitoring.enabled: true
xpack.monitoring.elasticsearch.username: ${ES_USER}
xpack.monitoring.elasticsearch.password: ${ES_PW}
xpack.monitoring.elasticsearch.hosts: ["${ES_ENDPOINT}"]
EOF

  $CURRENT_DIR/../../bin/logstash --path.settings $CURRENT_DIR 2>/dev/null &

  export LS_PID=$!
}

check_logstash_readiness() {
  count=120
  echo "Waiting Logstash to respond..."
  while ! curl --silent localhost:9600 && [[ $count -ne -1 ]]; do
      count=$(( $count - 1 ))
      [[ $count -eq 0 ]] && return 1
      sleep 1
  done
  echo "Logstash is Up !"
  return 0
}

check_logstash_api() {
  count=60
  echo "Checking Logstash API..."
  while ! [[ `curl --silent localhost:9600/_node/stats | jq "$1"` -ge $2 ]] && [[ $count -ne -1 ]]; do
      count=$(( $count - 1 ))
      [[ $count -eq 0 ]] && echo "1" && return
      sleep 1
  done
  echo "Passed check"
  echo "0"
}

clean_up() {
  kill $LS_PID
  echo "Done"
} 

setup_vault
build_logstash
INITIAL_MONITOR_CNT=$(get_monitor_count)
prepare_cpm_pipelines
run_logstash
check_logstash_readiness

# check es-output, implicitly 
PLUGIN_ES_OUTPUT=$(check_logstash_api '.pipelines.gen_es.plugins.outputs[0].documents.successes' '100')
PLUGIN_ES_OUTPUT="${PLUGIN_ES_OUTPUT: -1}"

# check es-input, depend on es-output
PLUGIN_ES_INPUT=$(check_logstash_api '.pipelines.es_stdout.plugins.inputs[0].events.out' '100')
PLUGIN_ES_INPUT="${PLUGIN_ES_INPUT: -1}"

# check es-filter, depend on es-output
PLUGIN_ES_FILTER=$(check_logstash_api '.pipelines.gen_es_stdout.plugins.filters[1].events.out' '100')
PLUGIN_ES_FILTER="${PLUGIN_ES_FILTER: -1}"

# check monitor
MONITOR_CNT=$(get_monitor_count)
if [[ "$MONITOR_CNT" -gt "$INITIAL_MONITOR_CNT" ]]; then
  MONITOR_CHECK=0
else
  MONITOR_CHECK=1
fi

clean_up

echo "es-output : es-input : es-filter : stack monitor"
echo "$PLUGIN_ES_OUTPUT : $PLUGIN_ES_INPUT : $PLUGIN_ES_FILTER : $MONITOR_CHECK"

if [[ ("$PLUGIN_ES_OUTPUT" -eq 0) && ("$PLUGIN_ES_INPUT" -eq 0) && ("$PLUGIN_ES_FILTER" -eq 0) && ("$MONITOR_CHECK" -eq 0) ]]; then
  exit 0
else
  exit 1
fi