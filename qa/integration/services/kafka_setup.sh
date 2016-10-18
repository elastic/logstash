#!/bin/bash
set -ex
current_dir="$(dirname "$0")"

source "$current_dir/helpers.sh"

if [ -n "${KAFKA_VERSION+1}" ]; then
    echo "KAFKA_VERSION is $KAFKA_VERSION"
    version=$KAFKA_VERSION
else
    version=0.10.0.1
fi

KAFKA_HOME=$INSTALL_DIR/kafka
KAFKA_TOPIC=logstash_topic_plain
KAFKA_MESSAGES=37

setup_kafka() {
    local version=$1
    if [ ! -d $KAFKA_HOME ]; then
        echo "Downloading Kafka version $version"
        curl -s -o $INSTALL_DIR/kafka.tgz "http://ftp.wayne.edu/apache/kafka/$version/kafka_2.11-$version.tgz"
        mkdir $KAFKA_HOME && tar xzf $INSTALL_DIR/kafka.tgz -C $KAFKA_HOME --strip-components 1
        rm $INSTALL_DIR/kafka.tgz
    fi
}

start_kafka() {
    echo "Starting ZooKeeper"
    $KAFKA_HOME/bin/zookeeper-server-start.sh -daemon $KAFKA_HOME/config/zookeeper.properties
    wait_for_port 2181
    echo "Starting Kafka broker"
    $KAFKA_HOME/bin/kafka-server-start.sh -daemon $KAFKA_HOME/config/server.properties --override delete.topic.enable=true --override log.dirs=/tmp/ls_integration/kafka-logs
    wait_for_port 9092
}

wait_for_messages() {
    local count=10
    local read_lines=0
    while [[ $read_lines -ne $KAFKA_MESSAGES ]] && [[ $count -ne 0 ]]; do
        read_lines=`$KAFKA_HOME/bin/kafka-console-consumer.sh --topic $KAFKA_TOPIC --new-consumer --bootstrap-server localhost:9092 --from-beginning --max-messages $KAFKA_MESSAGES | wc -l`
        count=$(( $count - 1 ))
        [[ $count -eq 0 ]] && return 1
        sleep 0.5
    done
}

setup_install_dir
setup_kafka $version
start_kafka
# Set up topics
$KAFKA_HOME/bin/kafka-topics.sh --create --partitions 1 --replication-factor 1 --topic logstash_topic_plain --zookeeper localhost:2181
# Add test messages to the newly created topic
cat $current_dir/../fixtures/how_sample.input | $KAFKA_HOME/bin/kafka-console-producer.sh --topic $KAFKA_TOPIC --broker-list localhost:9092
# Wait until broker has all messages
wait_for_messages
echo "Kafka Setup complete"
