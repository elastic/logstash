#!/usr/bin/env bash
set -ex

source ./$(dirname "$0")/common.sh

trap cpm_clean_up_and_get_result INT TERM EXIT
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
  check_logstash_api '.pipelines.gen_es.plugins.outputs[0].documents.successes' '100'
}

check_plugin() {
  add_check check_es_output "Failed central pipeline management check."
}

delete_pipeline() {
  curl -u "$ES_USER:$ES_PW" -X DELETE "$ES_ENDPOINT/_logstash/pipeline/$PIPELINE_NAME"  -H 'Content-Type: application/json';
}

cpm_clean_up_and_get_result() {
  delete_pipeline
  clean_up_and_get_result
}

prepare_cpm_pipelines
run_cpm_logstash check_plugin
