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
            rake artifact:all
        else
            # Qualifier is passed from CI as optional field and specify the version postfix
            # in case of alpha or beta releases:
            # e.g: 8.0.0-alpha1
            VERSION_QUALIFIER="$VERSION_QUALIFIER_OPT" rake artifact:all
            STACK_VERSION="${STACK_VERSION}-${VERSION_QUALIFIER_OPT}"
        fi
        STACK_VERSION=${STACK_VERSION}-SNAPSHOT
        info "Build complete, setting STACK_VERSION to $STACK_VERSION."
        ;;
    staging)
        info "Building artifacts for the $WORKFLOW_TYPE workflow..."
        if [ -z "$VERSION_QUALIFIER_OPT" ]; then
            RELEASE=1 rake artifact:all
        else
            # Qualifier is passed from CI as optional field and specify the version postfix
            # in case of alpha or beta releases:
            # e.g: 8.0.0-alpha1
            VERSION_QUALIFIER="$VERSION_QUALIFIER_OPT" RELEASE=1 rake artifact:all
            STACK_VERSION="${STACK_VERSION}-${VERSION_QUALIFIER_OPT}"
        fi
        info "Build complete, setting STACK_VERSION to $STACK_VERSION."
        ;;
    *)
        error "Workflow (WORKFLOW_TYPE variable) is not set, exiting..."
        ;;
esac

info "Saving tar.gz for docker images"
save_docker_tarballs "x86_64" "${STACK_VERSION}"

info "GENERATED ARTIFACTS"
for file in build/logstash-*; do shasum $file;done

info "Creating dependencies report for ${STACK_VERSION}"
mkdir -p build/distributions/dependencies-reports/
bin/dependencies-report --csv=build/distributions/dependencies-reports/logstash-${STACK_VERSION}.csv

info "GENERATED DEPENDENCIES REPORT"
shasum build/distributions/dependencies-reports/logstash-${STACK_VERSION}.csv

info "UPLOADING TO INTERMEDIATE BUCKET"
for file in build/logstash-*; do
  upload_to_bucket $file ${STACK_VERSION}
done

# Upload Dependencies Report
upload_to_bucket "build/distributions/dependencies-reports/logstash-${STACK_VERSION}.csv" ${STACK_VERSION}

for image in logstash logstash-oss logstash-ubi8; do
    upload_to_bucket "build/$image-${STACK_VERSION}-docker-image-x86_64.tar.gz" ${STACK_VERSION}
done

echo "####################################################################"
echo "##################### Finishing $0"
echo "####################################################################"
