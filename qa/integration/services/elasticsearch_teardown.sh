#!/bin/bash

my_dir="$(dirname "$0")"

stop_es() {
    pid=$(cat $current_dir/elasticsearch.pid)
    [ "x$pid" != "x" ] && [ "$pid" -gt 0 ]
    kill -SIGTERM $pid
}

stop_es