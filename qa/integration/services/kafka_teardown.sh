#!/bin/bash
set -ex
current_dir="$(dirname "$0")"
source "${current_dir}/helpers.sh"

# delete test topic
echo "Deleting test topic in Kafka"
$current_dir/kafka/bin/kafka-topics.sh --delete --topic logstash_topic_plain --zookeeper localhost:2181 --if-exists
stop_kafka
