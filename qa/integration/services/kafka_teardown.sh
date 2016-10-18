#!/bin/bash
set -ex
current_dir="$(dirname "$0")"

source "$current_dir/helpers.sh"

KAFKA_HOME=$INSTALL_DIR/kafka

stop_kafka() {
    echo "Stopping Kafka broker"
    $KAFKA_HOME/bin/kafka-server-stop.sh
    echo "Stopping zookeeper"
    $KAFKA_HOME/bin/zookeeper-server-stop.sh
}

# delete test topic
echo "Deleting test topic in Kafka"
$KAFKA_HOME/bin/kafka-topics.sh --delete --topic logstash_topic_plain --zookeeper localhost:2181 --if-exists
stop_kafka
rm -rf /tmp/ls_integration/kafka-logs
rm -rf /tmp/zookeeper

