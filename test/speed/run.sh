#!/bin/bash

root=$(dirname $0)/../../
workdir="$1"

if [ -z "$workdir" ] ; then
  echo "Usage: $0 <output dir>"
  exit 1
fi

run() {
  caller="${FUNCNAME[1]}"
  out="$workdir/${caller}.csv"
  echo "timestamp,count,rate_1m" > $out
  $root/bin/logstash agent -f <(m4 -DPATH="$out" bench.conf.erb)
}

default() {
  JRUBY_OPTS= JAVA_OPTS= run
}

indy() {
  JRUBY_OPTS="-Xjit.max=100000 -Xcompile.invokedynamic=true -Xcompile.fastest=true" run
}

default
indy
