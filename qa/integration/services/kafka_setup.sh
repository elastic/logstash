#!/bin/bash
set -ex
current_dir="$(dirname "$0")"
source "${current_dir}/helpers.sh"

if [ -n "${KAFKA_VERSION+1}" ]; then
    echo "KAFKA_VERSION is $KAFKA_VERSION"
    version=$KAFKA_VERSION
else
    version=0.10.0.0
fi

setup_kafka $version
start_kafka

# Set up topics
$current_dir/kafka/bin/kafka-topics.sh --create --partitions 1 --replication-factor 1 --topic logstash_topic_plain --zookeeper localhost:2181
cat $current_dir/kafka_input.input | $current_dir/kafka/bin/kafka-console-producer.sh --topic logstash_topic_plain --broker-list localhost:9092
echo "Kafka Setup complete"
