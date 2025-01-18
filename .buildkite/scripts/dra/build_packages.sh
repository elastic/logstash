#!/bin/bash -ie
#Note - ensure that the -e flag is set to properly set the $? status if any command fails
echo "####################################################################"
echo "##################### Starting $0"
echo "####################################################################"

source ./$(dirname "$0")/common.sh

# WORKFLOW_TYPE is a CI externally configured environment variable that could assume "snapshot" or "staging" values
info "Building artifacts for the $WORKFLOW_TYPE workflow ..."

case "$WORKFLOW_TYPE" in
    snapshot)
        :  # no-op
        ;;
    staging)
        export RELEASE=1
        ;;
    *)
        error "Workflow (WORKFLOW_TYPE variable) is not set, exiting..."
        ;;
esac

SKIP_DOCKER=1 rake artifact:all || error "rake artifact:all build failed."

if [[ "$WORKFLOW_TYPE" == "staging" ]] && [[ -n "$VERSION_QUALIFIER" ]]; then
    # Qualifier is passed from CI as optional field and specify the version postfix
    # in case of alpha or beta releases for staging builds only:
    # e.g: 8.0.0-alpha1
    STACK_VERSION="${STACK_VERSION}-${VERSION_QUALIFIER}"
fi

if [[ "$WORKFLOW_TYPE" == "snapshot" ]]; then
    STACK_VERSION="${STACK_VERSION}-SNAPSHOT"
fi

info "Build complete, setting STACK_VERSION to $STACK_VERSION."

info "Generated Artifacts"
for file in build/logstash-*; do shasum $file;done

info "Creating dependencies report for ${STACK_VERSION}"
mkdir -p build/distributions/dependencies-reports/
bin/dependencies-report --csv=build/distributions/dependencies-reports/logstash-${STACK_VERSION}.csv

info "Generated dependencies report"
shasum build/distributions/dependencies-reports/logstash-${STACK_VERSION}.csv

info "Uploading DRA artifacts in buildkite's artifact store ..."
buildkite-agent artifact upload "build/logstash*;build/distributions/dependencies-reports/logstash*"

echo "####################################################################"
echo "##################### Finishing $0"
echo "####################################################################"
