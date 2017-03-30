#!/bin/sh
# Run a ruby script using the logstash jruby launcher
#
# Usage:
#   bin/ruby [arguments]
#
# Supported environment variables:
#   LS_JVM_OPTS="xxx" path to file with JVM options
#   LS_JAVA_OPTS="xxx" to append extra options to the defaults JAVA_OPTS provided by logstash
#   JAVA_OPTS="xxx" to *completely override* the default set of JAVA_OPTS provided by logstash
#
# Development environment variables:
#   USE_RUBY=1 to force use the local "ruby" command to launch logstash instead of using the vendored JRuby
#   DEBUG=1 to output debugging information

# use faster starting JRuby options see https://github.com/jruby/jruby/wiki/Improving-startup-time
export JRUBY_OPTS="$JRUBY_OPTS -J-XX:+TieredCompilation -J-XX:TieredStopAtLevel=1"

unset CDPATH

. "$(cd `dirname $0`/..; pwd)/bin/logstash.lib.sh"
setup

ruby_exec "$@"
