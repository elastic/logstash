#!/bin/bash
set -ex
current_dir="$(dirname "$0")"

if [ -n "${ES_VERSION+1}" ]; then
  echo "Elasticsearch version is $ES_VERSION"
  version=$ES_VERSION
else
   version=5.0.0-alpha5
fi

setup_es() {
  if [ ! -d $current_dir/elasticsearch ]; then
      local version=$1
      download_url=https://download.elastic.co/elasticsearch/release/org/elasticsearch/distribution/tar/elasticsearch/$version/elasticsearch-$version.tar.gz
      curl -sL $download_url > $current_dir/elasticsearch.tar.gz
      mkdir $current_dir/elasticsearch
      tar -xzf $current_dir/elasticsearch.tar.gz --strip-components=1 -C $current_dir/elasticsearch/.
      rm $current_dir/elasticsearch.tar.gz
  fi
}

start_es() {
  es_args=$@
  $current_dir/elasticsearch/bin/elasticsearch $es_args -p $current_dir/elasticsearch/elasticsearch.pid > /tmp/elasticsearch.log 2>/dev/null &
  count=120
  echo "Waiting for elasticsearch to respond..."
  while ! curl --silent localhost:9200 && [[ $count -ne 0 ]]; do
      count=$(( $count - 1 ))
      [[ $count -eq 0 ]] && return 1
      sleep 1
  done
  echo "Elasticsearch is Up !"
  return 0
}

setup_es $version
start_es
