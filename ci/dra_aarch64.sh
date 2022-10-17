#!/bin/bash -ie
#Note - ensure that the -e flag is set to properly set the $? status if any command fails
echo "####################################################################"
echo "##################### Starting $0"
echo "####################################################################"

source ./$(dirname "$0")/dra_common.sh

# WORKFLOW_TYPE is a CI externally configured environment variable that could assume "snapshot" or "staging" values
case "$WORKFLOW_TYPE" in
    snapshot)
        info "Building artifacts for the $WORKFLOW_TYPE workflow..."
        if [ -z "$VERSION_QUALIFIER_OPT" ]; then
            rake artifact:docker
            rake artifact:docker_oss
            rake artifact:dockerfiles
        else
            VERSION_QUALIFIER="$VERSION_QUALIFIER_OPT" rake artifact:docker
            VERSION_QUALIFIER="$VERSION_QUALIFIER_OPT" rake artifact:docker_oss
            VERSION_QUALIFIER="$VERSION_QUALIFIER_OPT" rake artifact:dockerfiles
            # Qualifier is passed from CI as optional field and specify the version postfix
            # in case of alpha or beta releases:
            # e.g: 8.0.0-alpha1
            STACK_VERSION="${STACK_VERSION}-${VERSION_QUALIFIER_OPT}"
        fi
        STACK_VERSION=${STACK_VERSION}-SNAPSHOT
        info "Build complete, setting STACK_VERSION to $STACK_VERSION."
        ;;
    staging)
        info "Building artifacts for the $WORKFLOW_TYPE workflow..."
        if [ -z "$VERSION_QUALIFIER_OPT" ]; then
            RELEASE=1 rake artifact:docker
            RELEASE=1 rake artifact:docker_oss
            rake artifact:dockerfiles
        else
            VERSION_QUALIFIER="$VERSION_QUALIFIER_OPT" RELEASE=1 rake artifact:docker
            VERSION_QUALIFIER="$VERSION_QUALIFIER_OPT" RELEASE=1 rake artifact:docker_oss
            VERSION_QUALIFIER="$VERSION_QUALIFIER_OPT" rake artifact:dockerfiles
            # Qualifier is passed from CI as optional field and specify the version postfix
            # in case of alpha or beta releases:
            # e.g: 8.0.0-alpha1
            STACK_VERSION="${STACK_VERSION}-${VERSION_QUALIFIER_OPT}"
        fi
        info "Build complete, setting STACK_VERSION to $STACK_VERSION."
        ;;
    *)
        error "Workflow (WORKFLOW_TYPE variable) is not set, exiting..."
        ;;
esac

info "Saving tar.gz for docker images"
save_docker_tarballs "aarch64" "${STACK_VERSION}"

info "GENERATED ARTIFACTS"
for file in build/logstash-*; do shasum $file;done

info "UPLOADING TO INTERMEDIATE BUCKET"
# Note the deb, rpm tar.gz AARCH64 files generated has already been loaded by the dra_x86_64.sh
for image in logstash logstash-oss logstash-ubi8; do
    upload_to_bucket "build/$image-${STACK_VERSION}-docker-image-aarch64.tar.gz" ${STACK_VERSION}
done

echo "####################################################################"
echo "##################### Finishing $0"
echo "####################################################################"
