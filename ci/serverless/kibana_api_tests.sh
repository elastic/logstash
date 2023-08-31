#!/usr/bin/env bash

# This test is always fail because the APIs are not ready and return "method [...] exists but is not available with the current configuration"
set -ex

source ./$(dirname "$0")/common.sh

export PIPELINE_NAME="stdin_stdout"
export EXIT_CODE="0"

create_pipeline() {
    RESP_CODE=$(curl -s -w "%{http_code}" -o /dev/null -X PUT -H "Authorization: ApiKey $TESTER_API_KEY_ENCODED" "$KB_ENDPOINT/api/logstash/pipeline/$PIPELINE_NAME" \
      -H 'Content-Type: application/json' -H 'kbn-xsrf: logstash' \
      --data-binary @"$CURRENT_DIR/test_data/$PIPELINE_NAME.json")

    if [[ RESP_CODE -ge '400' ]]; then
      EXIT_CODE=$(( EXIT_CODE + 1 ))
      echo "Fail to create pipeline."
    fi
}

get_pipeline() {
    RESP_BODY=$(curl -s -X GET -H "Authorization: ApiKey $TESTER_API_KEY_ENCODED" "$KB_ENDPOINT/api/logstash/pipeline/$PIPELINE_NAME")
    SOURCE_BODY=$(cat "$CURRENT_DIR/test_data/$PIPELINE_NAME.json")

    RESP_PIPELINE_NAME=$(echo "$RESP_BODY" | jq -r '.id')

    RESP_PIPELINE=$(echo "$RESP_BODY" | jq -r '.pipeline')
    SOURCE_PIPELINE=$(echo "$SOURCE_BODY" | jq -r '.pipeline')

    RESP_SETTING=$(echo "$RESP_BODY" | jq -r '.settings')
    SOURCE_SETTING=$(echo "$SOURCE_BODY" | jq -r '.settings')


    # compare strings contain curly brackets
    if [[ ("$RESP_PIPELINE_NAME" -ne "$PIPELINE_NAME") || ("$RESP_PIPELINE" != "$SOURCE_PIPELINE") || ("$RESP_SETTING" != "$SOURCE_SETTING") ]]; then
      EXIT_CODE=$(( EXIT_CODE + 1 ))
      echo "Fail to get pipeline."
    fi

}

list_pipeline() {
    RESP_BODY=$(curl -s -X GET -H "Authorization: ApiKey $TESTER_API_KEY_ENCODED" "$KB_ENDPOINT/api/logstash/pipelines" | jq --arg name "$PIPELINE_NAME" '.pipelines[] | select(.id==$name)' )
    if [[ -z "$RESP_BODY" ]]; then
      EXIT_CODE=$(( EXIT_CODE + 1 ))
      echo "Fail to list pipeline."
    fi
}

delete_pipeline() {
    RESP_CODE=$(curl -s -w "%{http_code}" -o /dev/null -X DELETE -H "Authorization: ApiKey $TESTER_API_KEY_ENCODED" "$KB_ENDPOINT/api/logstash/pipeline/$PIPELINE_NAME" \
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