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
EXCLUDE_BRANCHES_ARRAY=()
BRANCHES=()

function install_yq() {
if ! [[ -x $(which yq) && $(yq --version) == *mikefarah* ]]; then
  echo "--- Downloading prerequisites"
  curl -fsSL --retry-max-time 60 --retry 3 --retry-delay 5 -o /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
  chmod a+x /usr/local/bin/yq
fi
}

function parse_pipelines() {
  IFS="," read -ra PIPELINES <<< "$PIPELINES_TO_TRIGGER"
}

# converts the (optional) $EXCLUDE_BRANCHES env var, containing a comma separated branches string, to $EXCLUDE_BRANCHES_ARRAY
function exclude_branches_to_array() {
  if [[ ! -z "$EXCLUDE_BRANCHES" ]]; then
    IFS="," read -ra EXCLUDE_BRANCHES_ARRAY <<< "$EXCLUDE_BRANCHES"
  fi
}

function check_if_branch_in_exclude_array() {
  local branch=$1
  local _excl_br
  local ret_val="false"

  for _excl_br in "${EXCLUDE_BRANCHES_ARRAY[@]}"; do
    if [[ "$branch" == "$_excl_br" ]]; then
      ret_val="true"
      break
    fi
  done

  echo $ret_val
}

if [[ -z $PIPELINES_TO_TRIGGER ]]; then
    echo "^^^ +++"
    echo "Required environment variable [PIPELINES_TO_TRIGGER] is missing."
    echo "Exiting now."
    exit 1
fi

parse_pipelines
exclude_branches_to_array

set -u
set +e
# pull releaseable branches from $ACTIVE_BRANCHES_URL
readarray -t ELIGIBLE_BRANCHES < <(curl --retry-all-errors --retry 5 --retry-delay 5 -fsSL $ACTIVE_BRANCHES_URL | jq -r '.branches[].branch')
if [[ $? -ne 0 ]]; then
  echo "There was an error downloading or parsing the json output from [$ACTIVE_BRANCHES_URL]. Exiting."
  exit 1
fi
set -e

if [[ ${#EXCLUDE_BRANCHES_ARRAY[@]} -eq 0 ]]; then
  # no branch exclusions
  BRANCHES=("${ELIGIBLE_BRANCHES[@]}")
else
  # exclude any branches passed via optional $EXCLUDE_BRANCHES
  for _branch in "${ELIGIBLE_BRANCHES[@]}"; do
    res=$(check_if_branch_in_exclude_array $_branch)
    if [[ "$res" == "false" ]]; then
      BRANCHES+=("$_branch")
    fi
  done
fi

install_yq

echo 'steps:' >pipeline_steps.yaml

for PIPELINE in "${PIPELINES[@]}"; do
  for BRANCH in "${BRANCHES[@]}"; do
      cat >>pipeline_steps.yaml <<EOF
  - trigger: $PIPELINE
    label: ":testexecute: Triggering ${PIPELINE} / ${BRANCH}"
    build:
      branch: "$BRANCH"
      message: ":testexecute: Scheduled build for ${BRANCH}"
EOF
  done
done

echo "--- Printing generated steps"
yq . pipeline_steps.yaml

echo "--- Uploading steps to buildkite"
cat pipeline_steps.yaml | buildkite-agent pipeline upload
