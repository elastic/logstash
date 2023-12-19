#!/usr/bin/env bash

set -eo pipefail

# *******************************************************
# this script is used by schedule-type pipelines
# to automate triggering other pipelines (e.g. DRA) based
# on ci/branches.json
#
# See:
# https://elasticco.atlassian.net/browse/ENGPRD-318 /
# https://github.com/elastic/ingest-dev/issues/2664
# *******************************************************

ACTIVE_BRANCHES_URL="https://raw.githubusercontent.com/elastic/logstash/main/ci/branches.json"

function install_yq() {
if ! [[ -x $(which yq) && $(yq --version) == *mikefarah* ]]; then
  echo "--- Downloading prerequisites"
  curl -fsSL --retry-max-time 60 --retry 3 --retry-delay 5 -o /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
  chmod a+x /usr/local/bin/yq
fi
}

if [[ -z $PIPELINE_TO_TRIGGER ]]; then
    echo "^^^ +++"
    echo "Required environment variable [PIPELINE_TO_TRIGGER] is missing."
    echo "Exiting now."
    exit 1
fi

set -u
set +e
BRANCHES=$(curl --retry-all-errors --retry 5 --retry-delay 5 -fsSL $ACTIVE_BRANCHES_URL | jq -r '.branches[].branch')
if [[ $? -ne 0 ]]; then
  echo "There was an error downloading or parsing the json output from [$ACTIVE_BRANCHES_URL]. Exiting."
  exit 1
fi

set -e

install_yq

echo 'steps:' >pipeline_steps.yaml

for BRANCH in $BRANCHES; do
    cat >>pipeline_steps.yaml <<EOF
  - trigger: $PIPELINE_TO_TRIGGER
    label: ":testexecute: Triggering ${PIPELINE_TO_TRIGGER} / ${BRANCH}"
    build:
      branch: "$BRANCH"
      message: ":testexecute: Scheduled build for ${BRANCH}"
EOF
done

echo "--- Printing generated steps"
yq . pipeline_steps.yaml

echo "--- Uploading steps to buildkite"
cat pipeline_steps.yaml | buildkite-agent pipeline upload
