#!/bin/bash -ie
#Note - ensure that the -e flag is set to properly set the $? status if any command fails

# Since we are using the system jruby, we need to make sure our jvm process
# uses at least 1g of memory, If we don't do this we can get OOM issues when
# installing gems. See https://github.com/elastic/logstash/issues/5179
export JRUBY_OPTS="-J-Xmx1g"

# Extract the version number from the version.yml file
# e.g.: 8.6.0
# The suffix part like alpha1 etc is managed by the optional VERSION_QUALIFIER_OPT environment variable
STACK_VERSION=`cat versions.yml | sed -n 's/^logstash\:\s\([[:digit:]]*\.[[:digit:]]*\.[[:digit:]]*\)$/\1/p'`
if [ -z "$WORKFLOW_TYPE"]; then
  STACK_VERSION=${STACK_VERSION}-SNAPSHOT
fi

if [ -z "$WORKFLOW_TYPE"]; then
  if [ -z "$VERSION_QUALIFIER_OPT" ]; then
    RELEASE=1 rake artifact:all
  else
    # Qualifier is passed from CI as optional field and specify the version postfix
    # in case of alpha or beta releases:
    # e.g: 8.0.0-alpha1
    VERSION_QUALIFIER="$VERSION_QUALIFIER_OPT" RELEASE=1 rake artifact:all
    STACK_VERSION="${STACK_VERSION}-${VERSION_QUALIFIER_OPT}"
  fi
else
  # WORKFLOW_TYPE is set, it has value "SNAPSHOT"
  if [ -z "$VERSION_QUALIFIER_OPT" ]; then
    rake artifact:all
  else
    VERSION_QUALIFIER="$VERSION_QUALIFIER_OPT" rake artifact:all
    STACK_VERSION="${STACK_VERSION}-${VERSION_QUALIFIER_OPT}"
  fi
fi

echo "Saving tar.gz for docker images"
docker save docker.elastic.co/logstash/logstash:${STACK_VERSION} | gzip -c > build/logstash-${STACK_VERSION}-docker-image-aarch64.tar.gz
docker save docker.elastic.co/logstash/logstash-oss:${STACK_VERSION} | gzip -c > build/logstash-oss-${STACK_VERSION}-docker-image-aarch64.tar.gz
docker save docker.elastic.co/logstash/logstash-ubi8:${STACK_VERSION} | gzip -c > build/logstash-ubi8-${STACK_VERSION}-docker-image-aarch64.tar.gz

echo "GENERATED ARTIFACTS"
for file in build/logstash-*; do shasum $file;done

echo "UPLOADING TO INTERMEDIATE BUCKET"
# Note the deb, rpm tar.gz AARCH64 files generated has already been loaded by the dra_x86_64.sh
gsutil cp build/logstash-${STACK_VERSION}-docker-image-aarch64.tar.gz gs://logstash-ci-artifacts/dra/${STACK_VERSION}/
gsutil cp build/logstash-oss-${STACK_VERSION}-docker-image-aarch64.tar.gz gs://logstash-ci-artifacts/dra/${STACK_VERSION}/
gsutil cp build/logstash-ubi8-${STACK_VERSION}-docker-image-aarch64.tar.gz gs://logstash-ci-artifacts/dra/${STACK_VERSION}/