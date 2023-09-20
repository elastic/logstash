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

if [ "$RELEASE_VER" != "7.17" ]; then
  # Version 7.17.x doesn't generates ARM artifacts for Darwin
  # TODO see if we need to do anything here
fi

# Deleting ubi8 for aarch64 for the time being. This image itself is not being built, and it is not expected
# by the release manager.
# See https://github.com/elastic/infra/blob/master/cd/release/release-manager/project-configs/8.5/logstash.gradle
# for more details.
# TODO filter it out when uploading artifacts instead
rm build/logstash-ubi8-${STACK_VERSION}-docker-image-aarch64.tar.gz

info "Downloaded ARTIFACTS sha report"
for file in build/logstash-*; do shasum $file;done

mv build/distributions/dependencies-reports/logstash-${STACK_VERSION}.csv build/distributions/dependencies-${STACK_VERSION}.csv

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
  -e VAULT_ADDR="${VAULT_ADDR_SECRET}" \
  -e VAULT_ROLE_ID="${VAULT_ROLE_ID_SECRET}" \
  -e VAULT_SECRET_ID="${VAULT_SECRET}" \
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
