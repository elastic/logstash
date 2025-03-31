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
QUALIFIED_VERSION="$(.buildkite/scripts/common/qualified-version.sh)"
SHA="$(git rev-parse --short HEAD)"
REGISTRY_PATH=docker.elastic.co/logstash/logstash-observability-sre

# Add architecture to the tags
ARCH_TAG="${ARCH:-x86_64}"  # Default to x86_64 if ARCH is not set

echo "Architecture: ${ARCH_TAG}"

# Push a unique tag (version + SHA) for the current build WITH the architecture in the name
# Ex: docker.elastic.co/logstash/logstash-observability-sre:8.19.0-SNAPSHOT-297226b1df-aarch64
SHA_ARCH_TAG="${QUALIFIED_VERSION}-${SHA}-${ARCH_TAG}"
echo "Tagging and pushing: ${REGISTRY_PATH}:${QUALIFIED_VERSION} as ${REGISTRY_PATH}:${SHA_ARCH_TAG}"
docker tag ${REGISTRY_PATH}:${QUALIFIED_VERSION} ${REGISTRY_PATH}:${SHA_ARCH_TAG}
docker push ${REGISTRY_PATH}:${SHA_ARCH_TAG}

# Teardown Docker environment
source .buildkite/scripts/dra/docker-env-teardown.sh