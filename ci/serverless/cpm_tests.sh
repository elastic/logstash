#!/usr/bin/env bash
set -ex

source ./$(dirname "$0")/common.sh

setup_vault
build_logstash

# test
export PIPELINE_NAME='gen_es'

# update pipeline and check response code
index_pipeline() {
  RESP_CODE=$(curl -s -w "%{http_code}" -X PUT -u "$ES_USER:$ES_PW" "$ES_ENDPOINT/_logstash/pipeline/$1"  -H 'Content-Type: application/json' -d "$2")
  if [[ $RESP_CODE -ge '400' ]]; then
    echo "failed to update pipeline for Central Pipeline Management. Got $RESP_CODE from Elasticsearch"
    exit 1
  fi
}

# index pipeline to serverless ES
prepare_cpm_pipelines() {
  index_pipeline "$PIPELINE_NAME" '{
    "pipeline": "input { generator { count => 100 } } output { elasticsearch { hosts => \"${ES_ENDPOINT}\" user => \"${ES_USER}\" password => \"${ES_PW}\" index=> \"${INDEX_NAME}\" } }",
    "last_modified": "2023-07-04T22:22:22.222Z",
    "pipeline_metadata": { "version": "1"},
    "username": "log.stash",
    "pipeline_settings": {"pipeline.batch.delay": "50"}
  }'
}

check_es_output() {
  PLUGIN_ES_OUTPUT=$(check_logstash_api '.pipelines.gen_es.plugins.outputs[0].documents.successes' '100')
  export PLUGIN_ES_OUTPUT="${PLUGIN_ES_OUTPUT: -1}"
}

clean_up() {
  curl -u "$ES_USER:$ES_PW" -X DELETE "$ES_ENDPOINT/_logstash/pipeline/$PIPELINE_NAME"  -H 'Content-Type: application/json';
  kill $LS_PID
  echo "Done"
}

prepare_cpm_pipelines
run_cpm_logstash check_es_output


trap clean_up EXIT
exit $PLUGIN_ES_OUTPUT