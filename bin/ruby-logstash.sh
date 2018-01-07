#!/usr/bin/env bash

unset CDPATH

. "$(cd `dirname $0`/..; pwd)/bin/logstash.lib.sh"
setup

ruby_exec "${LOGSTASH_HOME}/lib/bootstrap/environment.rb" "logstash/runner.rb" "$@"
