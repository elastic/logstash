#!/bin/bash -iex
#Note - ensure that the -e flag is set to properly set the $? status if any command fails
echo "####################################################################"
echo "##################### Starting $0"
echo "####################################################################"

source ./$(dirname "$0")/dra_common.sh
PLAIN_STACK_VERSION=$STACK_VERSION

# This is the branch selector that needs to be passed to the release-manager
# It has to be the name of the branch which originates the artifacts.
RELEASE_VER=`cat versions.yml | sed -n 's/^logstash\:[[:space:]]\([[:digit:]]*\.[[:digit:]]*\)\.[[:digit:]]*$/\1/p'`
if [ -n "$(git ls-remote --heads origin $RELEASE_VER)" ] ; then
    RELEASE_BRANCH=$RELEASE_VER
else
    RELEASE_BRANCH=main
fi

if [ -n "$VERSION_QUALIFIER_OPT" ]; then
  # Qualifier is passed from CI as optional field and specify the version postfix
  # in case of alpha or beta releases:
  # e.g: 8.0.0-alpha1
  STACK_VERSION="${STACK_VERSION}-${VERSION_QUALIFIER_OPT}"
  PLAIN_STACK_VERSION="${PLAIN_STACK_VERSION}-${VERSION_QUALIFIER_OPT}"
fi

case "$WORKFLOW_TYPE" in
    snapshot)
        STACK_VERSION=${STACK_VERSION}-SNAPSHOT
        ;;
    staging)
        ;;
    *)
        error "Worklflow (WORKFLOW_TYPE variable) is not set, exiting..."
        ;;
esac

info "Uploading artifacts for ${WORKFLOW_TYPE} workflow on branch: ${RELEASE_BRANCH}"

info "Download all the artifacts for version ${STACK_VERSION}"
mkdir build/
gsutil cp gs://logstash-ci-artifacts/dra/${STACK_VERSION}/logstash-${STACK_VERSION}-no-jdk.deb build/
gsutil cp gs://logstash-ci-artifacts/dra/${STACK_VERSION}/logstash-${STACK_VERSION}.csv build/

# no arch
gsutil cp gs://logstash-ci-artifacts/dra/${STACK_VERSION}/logstash-${STACK_VERSION}-no-jdk.deb build/
gsutil cp gs://logstash-ci-artifacts/dra/${STACK_VERSION}/logstash-${STACK_VERSION}-no-jdk.rpm build/
gsutil cp gs://logstash-ci-artifacts/dra/${STACK_VERSION}/logstash-${STACK_VERSION}-no-jdk.tar.gz build/
gsutil cp gs://logstash-ci-artifacts/dra/${STACK_VERSION}/logstash-${STACK_VERSION}-no-jdk.zip build/
gsutil cp gs://logstash-ci-artifacts/dra/${STACK_VERSION}/logstash-oss-${STACK_VERSION}-no-jdk.deb build/
gsutil cp gs://logstash-ci-artifacts/dra/${STACK_VERSION}/logstash-oss-${STACK_VERSION}-no-jdk.rpm build/
gsutil cp gs://logstash-ci-artifacts/dra/${STACK_VERSION}/logstash-oss-${STACK_VERSION}-no-jdk.tar.gz build/
gsutil cp gs://logstash-ci-artifacts/dra/${STACK_VERSION}/logstash-oss-${STACK_VERSION}-no-jdk.zip build/

# windows
gsutil cp gs://logstash-ci-artifacts/dra/${STACK_VERSION}/logstash-${STACK_VERSION}-windows-x86_64.zip build/
gsutil cp gs://logstash-ci-artifacts/dra/${STACK_VERSION}/logstash-oss-${STACK_VERSION}-windows-x86_64.zip build/

# unix x86
gsutil cp gs://logstash-ci-artifacts/dra/${STACK_VERSION}/logstash-${STACK_VERSION}-amd64.deb build/
gsutil cp gs://logstash-ci-artifacts/dra/${STACK_VERSION}/logstash-${STACK_VERSION}-x86_64.rpm build/
gsutil cp gs://logstash-ci-artifacts/dra/${STACK_VERSION}/logstash-${STACK_VERSION}-linux-x86_64.tar.gz build/
gsutil cp gs://logstash-ci-artifacts/dra/${STACK_VERSION}/logstash-${STACK_VERSION}-darwin-x86_64.tar.gz build/
gsutil cp gs://logstash-ci-artifacts/dra/${STACK_VERSION}/logstash-oss-${STACK_VERSION}-amd64.deb build/
gsutil cp gs://logstash-ci-artifacts/dra/${STACK_VERSION}/logstash-oss-${STACK_VERSION}-x86_64.rpm build/
gsutil cp gs://logstash-ci-artifacts/dra/${STACK_VERSION}/logstash-oss-${STACK_VERSION}-linux-x86_64.tar.gz build/
gsutil cp gs://logstash-ci-artifacts/dra/${STACK_VERSION}/logstash-oss-${STACK_VERSION}-darwin-x86_64.tar.gz build/

# unix ARM
gsutil cp gs://logstash-ci-artifacts/dra/${STACK_VERSION}/logstash-${STACK_VERSION}-arm64.deb build/
gsutil cp gs://logstash-ci-artifacts/dra/${STACK_VERSION}/logstash-${STACK_VERSION}-aarch64.rpm build/
gsutil cp gs://logstash-ci-artifacts/dra/${STACK_VERSION}/logstash-${STACK_VERSION}-linux-aarch64.tar.gz build/
gsutil cp gs://logstash-ci-artifacts/dra/${STACK_VERSION}/logstash-oss-${STACK_VERSION}-arm64.deb build/
gsutil cp gs://logstash-ci-artifacts/dra/${STACK_VERSION}/logstash-oss-${STACK_VERSION}-aarch64.rpm build/
gsutil cp gs://logstash-ci-artifacts/dra/${STACK_VERSION}/logstash-oss-${STACK_VERSION}-linux-aarch64.tar.gz build/

if [ "$RELEASE_VER" != "7.17" ]; then
  # Version 7.17.x doesn't generates ARM artifacts for Darwin   
  gsutil cp gs://logstash-ci-artifacts/dra/${STACK_VERSION}/logstash-${STACK_VERSION}-darwin-aarch64.tar.gz build/
  gsutil cp gs://logstash-ci-artifacts/dra/${STACK_VERSION}/logstash-oss-${STACK_VERSION}-darwin-aarch64.tar.gz build/
fi

# docker
gsutil cp gs://logstash-ci-artifacts/dra/${STACK_VERSION}/logstash-${STACK_VERSION}-docker-build-context.tar.gz build/
gsutil cp gs://logstash-ci-artifacts/dra/${STACK_VERSION}/logstash-ironbank-${STACK_VERSION}-docker-build-context.tar.gz build/
gsutil cp gs://logstash-ci-artifacts/dra/${STACK_VERSION}/logstash-oss-${STACK_VERSION}-docker-build-context.tar.gz build/
gsutil cp gs://logstash-ci-artifacts/dra/${STACK_VERSION}/logstash-ubi8-${STACK_VERSION}-docker-build-context.tar.gz build/

# docker x86
gsutil cp gs://logstash-ci-artifacts/dra/${STACK_VERSION}/logstash-${STACK_VERSION}-docker-image-x86_64.tar.gz build/
gsutil cp gs://logstash-ci-artifacts/dra/${STACK_VERSION}/logstash-oss-${STACK_VERSION}-docker-image-x86_64.tar.gz build/
gsutil cp gs://logstash-ci-artifacts/dra/${STACK_VERSION}/logstash-ubi8-${STACK_VERSION}-docker-image-x86_64.tar.gz build/

# docker ARM
gsutil cp gs://logstash-ci-artifacts/dra/${STACK_VERSION}/logstash-${STACK_VERSION}-docker-image-aarch64.tar.gz build/
gsutil cp gs://logstash-ci-artifacts/dra/${STACK_VERSION}/logstash-oss-${STACK_VERSION}-docker-image-aarch64.tar.gz build/
gsutil cp gs://logstash-ci-artifacts/dra/${STACK_VERSION}/logstash-ubi8-${STACK_VERSION}-docker-image-aarch64.tar.gz build/

gsutil cp gs://logstash-ci-artifacts/dra/${STACK_VERSION}/logstash-${STACK_VERSION}.csv build/

info "Downloaded ARTIFACTS"
for file in build/logstash-*; do shasum $file;done

mkdir -p build/distributions/dependencies-reports/
mv build/logstash-${STACK_VERSION}.csv build/distributions/dependencies-${STACK_VERSION}.csv

# set required permissions on artifacts and directory
chmod -R a+r build/*
chmod -R a+w build

chmod -R a+r $PWD/*
chmod -R a+w $PWD

# ensure the latest image has been pulled
docker pull docker.elastic.co/infra/release-manager:latest

# collect the artifacts for use with the unified build
docker run --rm \
  --name release-manager \
  -e VAULT_ADDR \
  -e VAULT_ROLE_ID \
  -e VAULT_SECRET_ID \
  --mount type=bind,readonly=false,src="$PWD",target=/artifacts \
  docker.elastic.co/infra/release-manager:latest \
    cli collect \
      --project logstash \
      --branch ${RELEASE_BRANCH} \
      --commit "$(git rev-parse HEAD)" \
      --workflow "${WORKFLOW_TYPE}" \
      --version "${PLAIN_STACK_VERSION}" \
      --artifact-set main

echo "####################################################################"
echo "##################### Finishing $0"
echo "####################################################################"
