#!/bin/bash
# Script to create and push Docker manifest for multi-architecture support
# This MUST be run after build-and-push-observabilty-sre.sh!

source .buildkite/scripts/common/vm-agent.sh
source .buildkite/scripts/dra/docker-env-setup.sh

docker_login

# Set INCLUDE_COMMIT_ID to include git SHA in version
QUALIFIED_VERSION="$(INCLUDE_COMMIT_ID=1 .buildkite/scripts/common/qualified-version.sh)"
REGISTRY_PATH=docker.elastic.co/logstash/logstash-observability-sre

# Architecture-specific tags (created by the build steps)
X86_64_TAG="${QUALIFIED_VERSION}-x86_64"
AARCH64_TAG="${QUALIFIED_VERSION}-aarch64"

# Target manifest tags - already has SHA from QUALIFIED_VERSION
VERSION_MANIFEST_TAG="${QUALIFIED_VERSION}"

# Create and push manifest with version (which already includes SHA)
echo "Creating manifest list for: ${REGISTRY_PATH}:${VERSION_MANIFEST_TAG}"
docker manifest create ${REGISTRY_PATH}:${VERSION_MANIFEST_TAG} \
  ${REGISTRY_PATH}:${X86_64_TAG} \
  ${REGISTRY_PATH}:${AARCH64_TAG}

docker manifest annotate ${REGISTRY_PATH}:${VERSION_MANIFEST_TAG} \
  ${REGISTRY_PATH}:${X86_64_TAG} --os linux --arch amd64

docker manifest annotate ${REGISTRY_PATH}:${VERSION_MANIFEST_TAG} \
  ${REGISTRY_PATH}:${AARCH64_TAG} --os linux --arch arm64

echo "Pushing manifest: ${REGISTRY_PATH}:${VERSION_MANIFEST_TAG}"
docker manifest push ${REGISTRY_PATH}:${VERSION_MANIFEST_TAG}

# Also create version without SHA for effective "latest" tag
BASE_VERSION="$(.buildkite/scripts/common/qualified-version.sh)"
echo "Creating manifest list for: ${REGISTRY_PATH}:${BASE_VERSION}"
docker manifest create ${REGISTRY_PATH}:${BASE_VERSION} \
  ${REGISTRY_PATH}:${X86_64_TAG} \
  ${REGISTRY_PATH}:${AARCH64_TAG}

docker manifest annotate ${REGISTRY_PATH}:${BASE_VERSION} \
  ${REGISTRY_PATH}:${X86_64_TAG} --os linux --arch amd64

docker manifest annotate ${REGISTRY_PATH}:${BASE_VERSION} \
  ${REGISTRY_PATH}:${AARCH64_TAG} --os linux --arch arm64

echo "Pushing manifest: ${REGISTRY_PATH}:${BASE_VERSION}"
docker manifest push ${REGISTRY_PATH}:${BASE_VERSION}

# Teardown Docker environment
source .buildkite/scripts/dra/docker-env-teardown.sh