#!/usr/bin/env bash
set -ex

source ./$(dirname "$0")/common.sh

# install plugin
"$CURRENT_DIR/../../bin/logstash-plugin" install logstash-filter-elastic_integration

# test
prepare_ingest_pipeline() {
  PIPELINE_RESP_CODE=$(curl -s -w "%{http_code}" -o /dev/null -X PUT -u "$ES_USER:$ES_PW" "$ES_ENDPOINT/_ingest/pipeline/integration-logstash_test.events-default" \
    -H 'Content-Type: application/json' \
    --data-binary @"$CURRENT_DIR/test_data/ingest_pipeline.json")

  TEMPLATE_RESP_CODE=$(curl -s -w "%{http_code}" -o /dev/null -X PUT -u "$ES_USER:$ES_PW" "$ES_ENDPOINT/_index_template/logs-generic-default-pipeline" \
    -H 'Content-Type: application/json' \
    --data-binary @"$CURRENT_DIR/test_data/index_template.json")

  if [[ $PIPELINE_RESP_CODE -ge '400' ]]; then
    ERR_MSGS+=("Failed to update ingest pipeline. Got $PIPELINE_RESP_CODE")
  fi

  if [[ $TEMPLATE_RESP_CODE -ge '400' ]]; then
    ERR_MSGS+=("Failed to update index template. Got $TEMPLATE_RESP_CODE")
  fi
}
check_integration_filter() {
  PLUGIN_CHECK=$(check_logstash_api '.pipelines.main.plugins.filters[] | select(.id == "check1") | .events.out' '1')
  PLUGIN_CHECK="${PLUGIN_CHECK: -1}"

  append_err_msg "$PLUGIN_CHECK" "Failed integration filter check."
  CHECKS+=("$PLUGIN_CHECK")
}

prepare_ingest_pipeline
run_logstash "$CURRENT_DIR/pipeline/004_integration-filter.conf" check_integration_filter

trap clean_up_and_check EXIT