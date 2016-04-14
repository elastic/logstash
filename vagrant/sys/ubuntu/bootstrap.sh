#!/usr/bin/env bash

apt-get update

apt-get install -y openjdk-7-jdk git g++
apt-get install -y git-core curl zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev python-software-properties libffi-dev

##
# Install logstash from a package repo
##
#wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | apt-key add -
#echo "deb http://packages.elastic.co/logstash/2.2/debian stable main" | tee -a /etc/apt/sources.list
#apt-get update

##
# Install logstash manually from a URL
##
BRANCH=${LOGSTASH_BRANCH:-'master'}
BUILD_URL='https://s3-eu-west-1.amazonaws.com/build-eu.elasticsearch.org/logstash'
URL="$BUILD_URL/$BRANCH/nightly/JDK8/logstash-latest-SNAPSHOT.deb"
wget $URL
dpkg -i "$HOME/logstash-latest-SNAPSHOT.deb"
