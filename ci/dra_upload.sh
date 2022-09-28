#!/bin/bash -ie
#Note - ensure that the -e flag is set to properly set the $? status if any command fails

# Since we are using the system jruby, we need to make sure our jvm process
# uses at least 1g of memory, If we don't do this we can get OOM issues when
# installing gems. See https://github.com/elastic/logstash/issues/5179
export JRUBY_OPTS="-J-Xmx1g"

STACK_VERSION=`cat versions.yml | sed -n 's/^logstash\:\s\([[:digit:]]*\.[[:digit:]]*\.[[:digit:]]*\)$/\1/p'`

echo "Download all the artifacts for version ${STACK_VERSION}"
mkdir build/
gsutil cp gs://logstash-ci-artifacts/dra/${STACK_VERSION}/ build/

echo "Downloaded ARTIFACTS"
for file in build/logstash-*; do shasum $file;done

# # set required permissions on artifacts and directory
# chmod -R a+r build/*
# chmod -R a+w build
# 
# # ensure the latest image has been pulled
# docker pull docker.elastic.co/infra/release-manager:latest
# 
# # collect the artifacts for use with the unified build
# docker run --rm \
#   --name release-manager \
#   -e VAULT_ADDR \
#   -e VAULT_ROLE_ID \
#   -e VAULT_SECRET_ID \
#   --mount type=bind,readonly=false,src="$PWD",target=/artifacts \
#   docker.elastic.co/infra/release-manager:latest \
#     cli collect \
#       --project logstash \
#       --branch 8.4 \
#       --commit "$(git rev-parse HEAD)" \
#       --workflow "staging" \
#       --version "${STACK_VERSION}" \
#       --artifact-set main