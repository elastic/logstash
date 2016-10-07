#!/bin/bash
set -e
current_dir="$(dirname "$0")"

source "$current_dir/helpers.sh"

ES_HOME=$INSTALL_DIR/elasticsearch

stop_es() {
    pid=$(cat $ES_HOME/elasticsearch.pid)
    [ "x$pid" != "x" ] && [ "$pid" -gt 0 ]
    kill -SIGTERM $pid
}

stop_es