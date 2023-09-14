#!/bin/bash
# Init vault
VAULT_TOKEN=$(vault write -field=token auth/approle/login role_id="$VAULT_ROLE_ID" secret_id="$VAULT_SECRET_ID")
export VAULT_TOKEN
unset VAULT_ROLE_ID VAULT_SECRET_ID

SONAR_TOKEN=$(vault read -field=token secret/logstash-ci/sonar-creds)
unset VAULT_TOKEN
DOCKER_ENV_OPTS="-e SONAR_TOKEN=${SONAR_TOKEN} -e SOURCE_BRANCH=$ghprbSourceBranch -e TARGET_BRANCH=$ghprbTargetBranch -e PULL_ID=$ghprbPullId -e COMMIT_SHA=$branch_specifier" \
 ci/docker_run.sh logstash-unit-tests ci/unit_tests.sh $@
