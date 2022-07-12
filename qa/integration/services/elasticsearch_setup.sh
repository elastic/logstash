#!/bin/bash
set -ex
current_dir="$(dirname "$0")"

source "$current_dir/helpers.sh"

ES_HOME="$current_dir/../../../build/elasticsearch"

start_es() {
  es_args=$@
  JAVA_HOME= $ES_HOME/bin/elasticsearch -Expack.security.enabled=false -Epath.data=/tmp/ls_integration/es-data -Ediscovery.type=single-node -Epath.logs=/tmp/ls_integration/es-logs $es_args -p $ES_HOME/elasticsearch.pid > /tmp/elasticsearch.log 2>/dev/null &
  count=120
  echo "Waiting for elasticsearch to respond..."
  while ! curl --silent localhost:9200 && [[ $count -ne 0 ]]; do
      count=$(( $count - 1 ))
      [[ $count -eq 0 ]] && cat /tmp/elasticsearch.log && return 1
      sleep 1
  done
  echo "Elasticsearch is Up !"
  return 0
}

export ES_JAVA_OPTS="-Xms512m -Xmx512m"
start_es
