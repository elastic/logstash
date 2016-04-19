#!/usr/bin/env bash

yum update
yum install -y java-1.8.0-openjdk-devel.x86_64

##
# Install logstash manually from a URL
##
BRANCH=${LOGSTASH_BRANCH:-'master'}
BUILD_URL='https://s3-eu-west-1.amazonaws.com/build-eu.elasticsearch.org/logstash'
URL="$BUILD_URL/$BRANCH/nightly/JDK8/logstash-latest-SNAPSHOT.rpm"
wget --no-verbose $URL
