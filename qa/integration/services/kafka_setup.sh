#!/bin/bash
set -ex
current_dir="$(dirname "$0")"

if [ -n "${KAFKA_VERSION+1}" ]; then
    echo "KAFKA_VERSION is $KAFKA_VERSION"
    version=$KAFKA_VERSION
else
    version=0.10.0.0
fi

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

setup_kafka $version
start_kafka

# Set up topics
$current_dir/kafka/bin/kafka-topics.sh --create --partitions 1 --replication-factor 1 --topic logstash_topic_plain --zookeeper localhost:2181
cat $current_dir/kafka_input.input | $current_dir/kafka/bin/kafka-console-producer.sh --topic logstash_topic_plain --broker-list localhost:9092
echo "Kafka Setup complete"
