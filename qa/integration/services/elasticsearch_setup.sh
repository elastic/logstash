#!/bin/bash
set -ex
current_dir="$(dirname "$0")"

source "$current_dir/helpers.sh"

ES_HOME="$current_dir/../../../build/elasticsearch"
ES_DATA_PATH="/tmp/ls_integration/es-data"
ES_LOGS_PATH="/tmp/ls_integration/es-logs"

start_es() {
  es_args=$@
  mkdir -p $ES_DATA_PATH $ES_LOGS_PATH
  JAVA_HOME= $ES_HOME/bin/elasticsearch -Expack.security.enabled=false -Epath.data=$ES_DATA_PATH -Ediscovery.type=single-node -Epath.logs=$ES_LOGS_PATH $es_args -p $ES_HOME/elasticsearch.pid > /tmp/elasticsearch.log 2>/dev/null &
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
