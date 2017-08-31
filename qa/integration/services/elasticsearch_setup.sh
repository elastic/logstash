#!/bin/bash
set -ex
current_dir="$(dirname "$0")"

source "$current_dir/helpers.sh"

if [ -n "${ES_VERSION+1}" ]; then
  echo "Elasticsearch version is $ES_VERSION"
  version=$ES_VERSION
else
   version=5.0.1
fi

ES_HOME=$INSTALL_DIR/elasticsearch

setup_es() {
  if [ ! -d $ES_HOME ]; then
      local version=$1
      download_url=https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-$version.tar.gz
      curl -sL $download_url > $INSTALL_DIR/elasticsearch.tar.gz
      mkdir $ES_HOME
      tar -xzf $INSTALL_DIR/elasticsearch.tar.gz --strip-components=1 -C $ES_HOME/.
      rm $INSTALL_DIR/elasticsearch.tar.gz
  fi
}

start_es() {
  es_args=$@
  $ES_HOME/bin/elasticsearch $es_args -p $ES_HOME/elasticsearch.pid > /tmp/elasticsearch.log 2>/dev/null &
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

setup_install_dir
setup_es $version
start_es
