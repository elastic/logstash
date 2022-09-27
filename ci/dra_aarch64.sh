#!/bin/bash -ie
#Note - ensure that the -e flag is set to properly set the $? status if any command fails

# Since we are using the system jruby, we need to make sure our jvm process
# uses at least 1g of memory, If we don't do this we can get OOM issues when
# installing gems. See https://github.com/elastic/logstash/issues/5179
export JRUBY_OPTS="-J-Xmx1g"

if [ -z "$VERSION_QUALIFIER_OPT" ]; then
  RELEASE=1 rake artifact:docker
  RELEASE=1 rake artifact:docker_oss
  rake artifact:dockerfiles
else
  VERSION_QUALIFIER="$VERSION_QUALIFIER_OPT" RELEASE=1 rake artifact:docker
  VERSION_QUALIFIER="$VERSION_QUALIFIER_OPT" RELEASE=1 rake artifact:docker_oss
  VERSION_QUALIFIER="$VERSION_QUALIFIER_OPT" rake artifact:dockerfiles
fi

STACK_VERSION=`cat versions.yml | sed -n 's/^logstash\:\s\([[:digit:]]*\.[[:digit:]]*\.[[:digit:]]*\)$/\1/p'`

echo "Saving tar.gz for docker images"
docker save docker.elastic.co/logstash/logstash:${STACK_VERSION}-SNAPSHOT | gzip -c > build/logstash-${STACK_VERSION}-docker-image-aarch64.tar.gz
docker save docker.elastic.co/logstash/logstash-oss:${STACK_VERSION}-SNAPSHOT | gzip -c > build/logstash-oss-${STACK_VERSION}-docker-image-aarch64.tar.gz
docker save docker.elastic.co/logstash/logstash-ubi8:${STACK_VERSION}-SNAPSHOT | gzip -c > build/logstash-ubi8-${STACK_VERSION}-docker-image-aarch64.tar.gz

echo "GENERATED ARTIFACTS"
for file in build/logstash-*; do shasum $file;done