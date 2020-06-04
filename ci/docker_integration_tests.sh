#!/bin/bash
# we may pass "persistent_queues" to FEATURE_FLAG to enable PQ in the integration tests
export DOCKER_ENV_OPTS="${DOCKER_ENV_OPTS} -e FEATURE_FLAG"
ci/docker_run.sh logstash-integration-tests ci/integration_tests.sh $@
