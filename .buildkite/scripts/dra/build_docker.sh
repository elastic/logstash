#!/bin/bash -ie
#Note - ensure that the -e flag is set to properly set the $? status if any command fails
echo "####################################################################"
echo "##################### Starting $0"
echo "####################################################################"

source ./$(dirname "$0")/common.sh

# WORKFLOW_TYPE is a CI externally configured environment variable that could assume "snapshot" or "staging" values
case "$WORKFLOW_TYPE" in
    snapshot)
        info "Building artifacts for the $WORKFLOW_TYPE workflow..."
        if [ -z "$VERSION_QUALIFIER_OPT" ]; then
            rake artifact:docker || error "artifact:docker build failed."
            rake artifact:docker_oss || error "artifact:docker_oss build failed."
            rake artifact:dockerfiles || error "artifact:dockerfiles build failed."
            if [ "$ARCH" != "aarch64" ]; then
                rake artifact:docker_ubi8 || error "artifact:docker_ubi8 build failed."
            fi
        else
            VERSION_QUALIFIER="$VERSION_QUALIFIER_OPT" rake artifact:docker || error "artifact:docker build failed."
            VERSION_QUALIFIER="$VERSION_QUALIFIER_OPT" rake artifact:docker_oss || error "artifact:docker_oss build failed."
            VERSION_QUALIFIER="$VERSION_QUALIFIER_OPT" rake artifact:dockerfiles || error "artifact:dockerfiles build failed."
            if [ "$ARCH" != "aarch64" ]; then
                VERSION_QUALIFIER="$VERSION_QUALIFIER_OPT" rake artifact:docker_ubi8 || error "artifact:docker_ubi8 build failed."
            fi
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
            RELEASE=1 rake artifact:docker || error "artifact:docker build failed."
            RELEASE=1 rake artifact:docker_oss || error "artifact:docker_oss build failed."
            RELEASE=1 rake artifact:dockerfiles || error "artifact:dockerfiles build failed."
            if [ "$ARCH" != "aarch64" ]; then
                RELEASE=1 rake artifact:docker_ubi8 || error "artifact:docker_ubi8 build failed."
            fi
        else
            VERSION_QUALIFIER="$VERSION_QUALIFIER_OPT" RELEASE=1 rake artifact:docker || error "artifact:docker build failed."
            VERSION_QUALIFIER="$VERSION_QUALIFIER_OPT" RELEASE=1 rake artifact:docker_oss || error "artifact:docker_oss build failed."
            VERSION_QUALIFIER="$VERSION_QUALIFIER_OPT" RELEASE=1 rake artifact:dockerfiles || error "artifact:dockerfiles build failed."
            if [ "$ARCH" != "aarch64" ]; then
                VERSION_QUALIFIER="$VERSION_QUALIFIER_OPT" RELEASE=1 rake artifact:docker_ubi8 || error "artifact:docker_ubi8 build failed."
            fi
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
save_docker_tarballs "${ARCH}" "${STACK_VERSION}"

info "Generated Artifacts"
for file in build/logstash-*; do shasum $file;done

info "Uploading DRA artifacts in buildkite's artifact store ..."
# Note the deb, rpm tar.gz AARCH64 files generated has already been loaded by the build_packages.sh
images="logstash logstash-oss"
if [ "$ARCH" != "aarch64" ]; then
    # No logstash-ubi8 for AARCH64
    images="logstash logstash-oss logstash-ubi8"
fi
for image in ${images}; do
    buildkite-agent artifact upload "build/$image-${STACK_VERSION}-docker-image-${ARCH}.tar.gz"
done

# Upload 'docker-build-context.tar.gz' files only when build x86_64, otherwise they will be
# overwritten when building aarch64 (or viceversa).
if [ "$ARCH" != "aarch64" ]; then
    for image in logstash logstash-oss logstash-ubi8 logstash-ironbank; do
        buildkite-agent artifact upload "build/${image}-${STACK_VERSION}-docker-build-context.tar.gz"
    done
fi

echo "####################################################################"
echo "##################### Finishing $0"
echo "####################################################################"
