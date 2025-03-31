#!/bin/bash
# Script to create and push Docker manifest for multi-architecture support
# This MUST be fun after build-and-push-observabilty-sre.sh! 

source .buildkite/scripts/common/vm-agent.sh
source .buildkite/scripts/dra/docker-env-setup.sh

docker_login
QUALIFIED_VERSION="$(.buildkite/scripts/common/qualified-version.sh)"
SHA="$(git rev-parse --short HEAD)"
REGISTRY_PATH=docker.elastic.co/logstash/logstash-observability-sre

# Architecture-specific tags (created by the build steps)
X86_64_TAG="${QUALIFIED_VERSION}-${SHA}-x86_64"
AARCH64_TAG="${QUALIFIED_VERSION}-${SHA}-aarch64"

# Target manifest tags
SHA_MANIFEST_TAG="${QUALIFIED_VERSION}-${SHA}"
VERSION_MANIFEST_TAG="${QUALIFIED_VERSION}"

# Create and push manifest with SHA
echo "Creating manifest list for: ${REGISTRY_PATH}:${SHA_MANIFEST_TAG}"
docker manifest create ${REGISTRY_PATH}:${SHA_MANIFEST_TAG} \
  ${REGISTRY_PATH}:${X86_64_TAG} \
  ${REGISTRY_PATH}:${AARCH64_TAG}

docker manifest annotate ${REGISTRY_PATH}:${SHA_MANIFEST_TAG} \
  ${REGISTRY_PATH}:${X86_64_TAG} --os linux --arch amd64

docker manifest annotate ${REGISTRY_PATH}:${SHA_MANIFEST_TAG} \
  ${REGISTRY_PATH}:${AARCH64_TAG} --os linux --arch arm64

echo "Pushing manifest: ${REGISTRY_PATH}:${SHA_MANIFEST_TAG}"
docker manifest push ${REGISTRY_PATH}:${SHA_MANIFEST_TAG}

# Create and push manifest without SHA (just version)
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

# Teardown Docker environment
source .buildkite/scripts/dra/docker-env-teardown.sh