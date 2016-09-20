#!/bin/bash
set -ex
current_dir="$(dirname "$0")"

stop_kafka() {
    echo "Stopping Kafka broker"
    $current_dir/kafka/bin/kafka-server-stop.sh
    sleep 2
    echo "Stopping zookeeper"
    $current_dir/kafka/bin/zookeeper-server-stop.sh
    sleep 2
}

# delete test topic
echo "Deleting test topic in Kafka"
$current_dir/kafka/bin/kafka-topics.sh --delete --topic logstash_topic_plain --zookeeper localhost:2181 --if-exists
stop_kafka
