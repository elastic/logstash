#!/usr/bin/env bash
set -ex

source ./$(dirname "$0")/common.sh

deploy_ingest_pipeline() {
  PIPELINE_RESP_CODE=$(curl -s -w "%{http_code}" -o /dev/null -X PUT -H "Authorization: ApiKey $TESTER_API_KEY_ENCODED" "$ES_ENDPOINT/_ingest/pipeline/integration-logstash_test.events-default" \
    -H 'Content-Type: application/json' \
    --data-binary @"$CURRENT_DIR/test_data/ingest_pipeline.json")

  TEMPLATE_RESP_CODE=$(curl -s -w "%{http_code}" -o /dev/null -X PUT -H "Authorization: ApiKey $TESTER_API_KEY_ENCODED" "$ES_ENDPOINT/_index_template/logs-serverless-default-template" \
    -H 'Content-Type: application/json' \
    --data-binary @"$CURRENT_DIR/test_data/index_template.json")

  # ingest pipeline is likely be there from the last run
  # failing to update pipeline does not stop the test
  if [[ $PIPELINE_RESP_CODE -ge '400' ]]; then
    ERR_MSGS+=("Failed to update ingest pipeline. Got $PIPELINE_RESP_CODE")
  fi

  if [[ $TEMPLATE_RESP_CODE -ge '400' ]]; then
    ERR_MSGS+=("Failed to update index template. Got $TEMPLATE_RESP_CODE")
  fi
}

# processor should append 'serverless' to message
check_integration_filter() {
  check_logstash_api '.pipelines.main.plugins.filters[] | select(.id == "mutate1") | .events.out' '1'
}

get_doc_msg_length() {
  curl -s -H "Authorization: ApiKey $TESTER_API_KEY_ENCODED" "$ES_ENDPOINT/logs-$INDEX_NAME.004-default/_search?size=1" | jq '.hits.hits[0]._source.message | length'
}

# ensure no double run of ingest pipeline
# message = ['ok', 'serverless*']
validate_ds_doc() {
   [[ $(get_doc_msg_length) -eq "2" ]] && echo "0"
}

check_doc_no_duplication() {
  count_down_check 20 validate_ds_doc
}

check_plugin() {
  add_check check_integration_filter "Failed ingest pipeline processor check."
  add_check check_doc_no_duplication "Failed ingest pipeline duplication check."
}

setup
# install plugin
"$CURRENT_DIR/../../bin/logstash-plugin" install logstash-filter-elastic_integration
deploy_ingest_pipeline
run_logstash "$CURRENT_DIR/pipeline/004_integration-filter.conf" check_plugin
