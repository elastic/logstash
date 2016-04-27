#!/usr/bin/env bash

apt-get update
apt-get install -y openjdk-7-jdk

##
# Install logstash manually from a URL
##
BRANCH=${LOGSTASH_BRANCH:-'master'}
BUILD_URL='https://s3-eu-west-1.amazonaws.com/build-eu.elasticsearch.org/logstash'
URL="$BUILD_URL/$BRANCH/nightly/JDK8/logstash-latest-SNAPSHOT.deb"
wget --no-verbose $URL
