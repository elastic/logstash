#!/bin/bash
set -e
current_dir="$(dirname "$0")"

source "$current_dir/helpers.sh"

ES_HOME="$current_dir/../../../build/elasticsearch"

stop_es() {
    local count=10
    [ ! -f $ES_HOME/elasticsearch.pid ] && return 0
    pid=$(cat $ES_HOME/elasticsearch.pid) 2>/dev/null
    if [ "x$pid" != "x" ] && [ "$pid" -gt 0 ]
    then
      while kill -SIGTERM "$pid" 2>/dev/null && [ $count -ne 0 ]; do
         echo "waiting for elasticsearch to stop"
         count=$(( $count - 1 ))
         [[ $count -eq 0 ]] && echo "killing elasticsearch" && kill -9 $pid 2>/dev/null || true
         sleep 0.5
      done
    fi
}

stop_es
rm -rf /tmp/ls_integration/es-data /tmp/ls_integration/es-logs

if [ -n "$ES_TLS_CERT" ]; then
  $ES_HOME/bin/elasticsearch-users userdel esadmin 2>/dev/null || true
  rm -f "$ES_HOME/config/es-server.crt" "$ES_HOME/config/es-server.key" "$ES_HOME/config/es-ca.crt"
fi
