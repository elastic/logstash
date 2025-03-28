#!/bin/bash
# Script to build and publish ObservabilitySRE container

echo "Setting up environment"
source .buildkite/scripts/common/vm-agent.sh
source .buildkite/scripts/dra/docker-env-setup.sh

echo "Building ObservabilitySRE container"
./gradlew --stacktrace artifactDockerObservabilitySRE -PfedrampHighMode=true

echo "Pushing ObservabilitySRE container to Docker repository"
docker_login
QUALIFIED_VERSION="$(.buildkite/scripts/common/qualified-version.sh)"
SHA="$(git rev-parse --short HEAD)"
REGISTRY_PATH=docker.elastic.co/logstash/logstash-observability-sre

if [[ "${WORKFLOW_TYPE}" == "staging" ]]; then
    # For staging builds, Push the original qualified version
    # Ex: docker.elastic.co/logstash/logstash-observability-sre:8.19.0
    docker push ${REGISTRY_PATH}:${QUALIFIED_VERSION}
fi

# For both staging and snapshot builds push the qualified version + the sha 
# Ex: docker.elastic.co/logstash/logstash-observability-sre:8.19.0-SNAPSHOT-297226b1df
SHA_TAG="${QUALIFIED_VERSION}-${SHA}"
docker tag ${REGISTRY_PATH}:${QUALIFIED_VERSION} ${REGISTRY_PATH}:${SHA_TAG}
docker push ${REGISTRY_PATH}:${SHA_TAG}

# Teardown Docker environment
source .buildkite/scripts/dra/docker-env-teardown.sh