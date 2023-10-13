#!/usr/bin/env bash

SONAR_TOKEN_PATH="kv/ci-shared/platform-ingest/elastic/logstash/sonar-creds"
export SONAR_TOKEN=$(retry -t 5 -- vault kv get -field=token ${SONAR_TOKEN_PATH})

export SOURCE_BRANCH=$GITHUB_PR_BRANCH
export TARGET_BRANCH=$GITHUB_PR_TARGET_BRANCH
export PULL_ID=$GITHUB_PR_NUMBER
export COMMIT_SHA=$BUILDKITE_COMMIT
