#!/bin/bash
# Script to build and publish ObservabilitySRE container
# Currently this is built on a host with the target architecture.
# This allows us to utilize the make file for building the container and
# to ensure the best compatability with the host architecture.
# A later step in CI will take care of pushing a tag that references the right
# image using `docker manifest` commands.

echo "Setting up environment"
source .buildkite/scripts/common/vm-agent.sh
source .buildkite/scripts/dra/docker-env-setup.sh

echo "Building ObservabilitySRE container"
./gradlew --stacktrace artifactDockerObservabilitySRE -PfedrampHighMode=true

echo "Pushing ObservabilitySRE container to Docker repository"
docker_login

# Get qualified version without SHA (this is what the gradle task will produce)
# Note that the gradle task always produces a version with -SNAPSHOT so if the
# workflow type is staging we need to append -SNAPSHOT to the version.
QUALIFIED_VERSION="$(.buildkite/scripts/common/qualified-version.sh)"
if [[ "${WORKFLOW_TYPE:-}" == "staging" && "${QUALIFIED_VERSION}" != *-SNAPSHOT ]]; then
  QUALIFIED_VERSION="${QUALIFIED_VERSION}-SNAPSHOT"
fi

# Set environment variable to include SHA and get version with SHA
QUALIFIED_VERSION_WITH_SHA="$(INCLUDE_COMMIT_ID=1 .buildkite/scripts/common/qualified-version.sh)"

REGISTRY_PATH=docker.elastic.co/logstash/logstash-observability-sre

# Current architecture
ARCH="${ARCH:-x86_64}"  # Default to x86_64 if ARCH is not set
echo "Architecture: ${ARCH}"

# Create the full tag with SHA and architecture
FULL_TAG="${QUALIFIED_VERSION_WITH_SHA}-${ARCH}"
echo "Tagging and pushing: ${REGISTRY_PATH}:${QUALIFIED_VERSION} as ${REGISTRY_PATH}:${FULL_TAG}"
docker tag ${REGISTRY_PATH}:${QUALIFIED_VERSION} ${REGISTRY_PATH}:${FULL_TAG}
docker push ${REGISTRY_PATH}:${FULL_TAG}

# Teardown Docker environment
source .buildkite/scripts/dra/docker-env-teardown.sh