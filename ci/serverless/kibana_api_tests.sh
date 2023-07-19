#!/usr/bin/env bash
set -ex

source ./$(dirname "$0")/common.sh

export PIPELINE_NAME="stdin_stdout"
export EXIT_CODE="0"

create_pipeline() {
    RESP_CODE=$(curl -s -w "%{http_code}" -o /dev/null -X PUT -u "$ES_USER:$ES_PW" "$KB_ENDPOINT/api/logstash/pipeline/$PIPELINE_NAME" \
      -H 'Content-Type: application/json' -H 'kbn-xsrf: logstash' \
      --data-binary @"$CURRENT_DIR/test_data/$PIPELINE_NAME.json")

    if [[ RESP_CODE -ge '400' ]]; then
      EXIT_CODE=$(( EXIT_CODE + 1 ))
      echo "Fail to create pipeline."
    fi
}

get_pipeline() {
    RESP_BODY=$(curl -s -X GET -u "$ES_USER:$ES_PW" "$KB_ENDPOINT/api/logstash/pipeline/$PIPELINE_NAME")

    SOURCE_BODY=$(cat "$CURRENT_DIR/test_data/$PIPELINE_NAME.json")

    if [[ $(echo "$RESP_BODY" | jq -r '.id') -ne "$PIPELINE_NAME" ]] ||\
      [[ $(echo "$RESP_BODY" | jq -r '.pipeline') -ne $(echo "$SOURCE_BODY" | jq -r '.pipeline') ]] ||\
      [[ $(echo "$RESP_BODY" | jq -r '.settings') -ne $(echo "$SOURCE_BODY" | jq -r '.settings') ]]; then

      EXIT_CODE=$(( EXIT_CODE + 1 ))
      echo "Fail to get pipeline."
    fi

}

list_pipeline() {
    RESP_BODY=$(curl -s -X GET -u "$ES_USER:$ES_PW" "$KB_ENDPOINT/api/logstash/pipelines" | jq --arg name "$PIPELINE_NAME" '.pipelines[] | select(.id==$name)' )
    if [[ -z "$RESP_BODY" ]]; then
      EXIT_CODE=$(( EXIT_CODE + 1 ))
      echo "Fail to list pipeline."
    fi
}

delete_pipeline() {
    RESP_CODE=$(curl -s -w "%{http_code}" -o /dev/null -X DELETE -u "$ES_USER:$ES_PW" "$KB_ENDPOINT/api/logstash/pipeline/$PIPELINE_NAME" \
      -H 'Content-Type: application/json' -H 'kbn-xsrf: logstash' \
      --data-binary @"$CURRENT_DIR/test_data/$PIPELINE_NAME.json")

    if [[ RESP_CODE -ge '400' ]]; then
      EXIT_CODE=$(( EXIT_CODE + 1 ))
      echo "Fail to delete pipeline."
    fi
}

setup_vault

create_pipeline
get_pipeline
list_pipeline
delete_pipeline

exit $EXIT_CODE