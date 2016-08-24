#! /bin/bash

current_dir="$(dirname "$0")"

setup_es() {
  if [ ! -d $current_dir/elasticsearch ]; then
      local version=$1
      download_url=https://download.elastic.co/elasticsearch/release/org/elasticsearch/distribution/tar/elasticsearch/$version/elasticsearch-$version.tar.gz
      curl -sL $download_url > $current_dir/elasticsearch.tar.gz
      mkdir $current_dir/elasticsearch
      tar -xzf $current_dir/elasticsearch.tar.gz --strip-components=1 -C $current_dir/elasticsearch/.
      rm $current_dir/elasticsearch.tar.gz
  fi
}

start_es() {
  es_args=$@
  $current_dir/elasticsearch/bin/elasticsearch $es_args -p $current_dir/elasticsearch.pid > /tmp/elasticsearch.log 2>/dev/null &
  count=120
  echo "Waiting for elasticsearch to respond..."
  while ! curl --silent localhost:9200 && [[ $count -ne 0 ]]; do
      count=$(( $count - 1 ))
      [[ $count -eq 0 ]] && return 1
      sleep 1
  done
  echo "Elasticsearch is Up !"
  return 0
}

stop_es() {
    pid=$(cat $current_dir/elasticsearch.pid)
    [ "x$pid" != "x" ] && [ "$pid" -gt 0 ]
    kill -SIGTERM $pid
}

setup_kafka() {
    local version=$1
    if [ ! -d $current_dir/kafka ]; then
        echo "Downloading Kafka version $version"
        curl -s -o $current_dir/kafka.tgz "http://ftp.wayne.edu/apache/kafka/$version/kafka_2.11-$version.tgz"
        mkdir $current_dir/kafka && tar xzf $current_dir/kafka.tgz -C $current_dir/kafka --strip-components 1
        rm $current_dir/kafka.tgz
    fi
}

start_kafka() {
    echo "Starting ZooKeeper"
    $current_dir/kafka/bin/zookeeper-server-start.sh -daemon $current_dir/kafka/config/zookeeper.properties
    sleep 3
    echo "Starting Kafka broker"
    $current_dir/kafka/bin/kafka-server-start.sh -daemon $current_dir/kafka/config/server.properties --override delete.topic.enable=true
    sleep 3
}

stop_kafka() {
    echo "Stopping Kafka broker"
    $current_dir/kafka/bin/kafka-server-stop.sh
    sleep 2
    echo "Stopping zookeeper"
    $current_dir/kafka/bin/zookeeper-server-stop.sh
    sleep 2
}