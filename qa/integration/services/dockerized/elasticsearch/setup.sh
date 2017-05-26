#!/bin/bash

if [ -n "${ES_VERSION+1}" ]; then
  echo "Elasticsearch version is $ES_VERSION"
  version=$ES_VERSION
else
   version=5.0.1
fi

ES_HOME=${WORKDIR}/elasticsearch

download_url=https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-$version.tar.gz
curl -s -o elasticsearch.tar.gz $download_url
mkdir -p $ES_HOME
tar -xzf elasticsearch.tar.gz --strip-components=1 -C $ES_HOME/.
