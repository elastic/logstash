#!/bin/bash

root=$(dirname $0)/../../
workdir="$1"
index="$workdir/_index.tsv"

if [ -z "$workdir" ] ; then
  echo "Usage: $0 <output dir>"
  exit 1
fi

run() {
  caller="${FUNCNAME[1]}"
  out="$workdir/${caller}.csv"

  # record this run's name and arguments
  echo "$caller	$@" >> $index

  # csv header
  echo "timestamp,count,rate_1m" > $out

  # run logstash
  env "$@" $root/bin/logstash agent -f <(m4 -DPATH="$out" bench.conf.erb)
}

default() {
  run JRUBY_OPTS= JAVA_OPTS=
}

indy() {
  run JRUBY_OPTS="-Xcompile.invokedynamic=true"
}

gctune() {
  run JAVA_OPTS="-XX:ReservedCodeCacheSize=128m -XX:+UseBiasedLocking -XX:+UseParNewGC -XX:+UseConcMarkSweepGC -XX:+CMSParallelRemarkEnabled -XX:SurvivorRatio=8 -XX:MaxTenuringThreshold=15 -XX:CMSInitiatingOccupancyFraction=75 -XX:+UseCMSInitiatingOccupancyOnly -XX:+HeapDumpOnOutOfMemoryError"
}

cp index.html $workdir/index.html

(
  echo "# logstash perf tests"

  echo "## ruby"
  ruby -v |& sed -e 's/^/    /'

  echo "## java"
  java -version |& sed -e 's/^/    /'
) > $workdir/README.md


echo "name	env" > $index
default
indy
gctune
