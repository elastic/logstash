#!/usr/bin/env bash

VERSION=`cat /vagrant/config/platforms.json | grep  latest | cut -d":" -f2 | sed 's/["\|,| ]//g'`
LOGSTASH_FILENAME="logstash-${VERSION}.noarch.rpm"
wget -q https://download.elastic.co/logstash/logstash/packages/centos/$LOGSTASH_FILENAME
mv $LOGSTASH_FILENAME "logstash-${VERSION}.rpm" # necessary patch until new version with the standard name format are released
