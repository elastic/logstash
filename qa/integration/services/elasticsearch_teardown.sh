#!/bin/bash
set -e
current_dir="$(dirname "$0")"

stop_es() {
    pid=$(cat $current_dir/elasticsearch/elasticsearch.pid)
    [ "x$pid" != "x" ] && [ "$pid" -gt 0 ]
    kill -SIGTERM $pid
}

stop_es