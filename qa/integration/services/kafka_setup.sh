#!/bin/bash
set -ex
current_dir="$(dirname "$0")"

export _JAVA_OPTIONS="-Djava.net.preferIPv4Stack=true"

source "$current_dir/helpers.sh"

if [ -n "${KAFKA_VERSION+1}" ]; then
    echo "KAFKA_VERSION is $KAFKA_VERSION"
    version=$KAFKA_VERSION
else
    version=2.7.0
fi

KAFKA_HOME=$INSTALL_DIR/kafka
KAFKA_TOPIC=logstash_topic_plain
KAFKA_MESSAGES=37
KAFKA_LOGS_DIR=/tmp/ls_integration/kafka-logs
ZOOKEEPER_DATA_DIR=/tmp/ls_integration/zookeeper

setup_kafka() {
    local version=$1
    if [ ! -d $KAFKA_HOME ]; then
        echo "Downloading Kafka version $version"
        curl -s -o $INSTALL_DIR/kafka.tgz "https://archive.apache.org/dist/kafka/$version/kafka_2.13-$version.tgz"
        mkdir $KAFKA_HOME && tar xzf $INSTALL_DIR/kafka.tgz -C $KAFKA_HOME --strip-components 1
        rm $INSTALL_DIR/kafka.tgz
        echo "dataDir=$ZOOKEEPER_DATA_DIR" >> $KAFKA_HOME/config/zookeeper.properties
    fi
}

start_kafka() {
    echo "Starting ZooKeeper"
    rm -rf ${KAFKA_LOGS_DIR}
    mkdir -p ${KAFKA_LOGS_DIR}
    rm -rf ${ZOOKEEPER_DATA_DIR}
    mkdir -p ${ZOOKEEPER_DATA_DIR} 
    $KAFKA_HOME/bin/zookeeper-server-start.sh -daemon $KAFKA_HOME/config/zookeeper.properties
    wait_for_port 2181
    $KAFKA_HOME/bin/kafka-server-start.sh -daemon $KAFKA_HOME/config/server.properties --override delete.topic.enable=true --override advertised.host.name=127.0.0.1 --override log.dir=${KAFKA_LOGS_DIR} --override log.dirs=${KAFKA_LOGS_DIR} --override log.flush.interval.ms=200 
    wait_for_port 9092
}

wait_for_messages() {
    local count=10
    local read_lines=0
    
    echo "Checking if Kafka topic has been populated with data"
    while [[ $read_lines -ne $KAFKA_MESSAGES ]] && [[ $count -ne 0 ]]; do
        read_lines=`$KAFKA_HOME/bin/kafka-console-consumer.sh --topic $KAFKA_TOPIC --bootstrap-server localhost:9092 --from-beginning --max-messages $KAFKA_MESSAGES --timeout-ms 10000 | wc -l`
        count=$(( $count - 1 ))
        [[ $count -eq 0 ]] && return 1
        sleep 0.5
        #ls -lrt $KAFKA_LOGS_DIR/$KAFKA_TOPIC-0/
    done
    echo "Kafka topic has been populated with test data"
}

setup_install_dir
setup_kafka $version
start_kafka
# Set up topics
$KAFKA_HOME/bin/kafka-topics.sh --create --partitions 1 --replication-factor 1 --topic $KAFKA_TOPIC --zookeeper localhost:2181
# check topic got created
num_topic=`$KAFKA_HOME/bin/kafka-topics.sh --list --zookeeper localhost:2181 | grep $KAFKA_TOPIC | wc -l`
[[ $num_topic -eq 1 ]]
# Add test messages to the newly created topic
cp $current_dir/../fixtures/how_sample.input $KAFKA_HOME
[[ ! -s  how_sample.input ]]
$KAFKA_HOME/bin/kafka-console-producer.sh --topic $KAFKA_TOPIC --broker-list localhost:9092 < $KAFKA_HOME/how_sample.input
echo "Kafka load status code $?"
# Wait until broker has all messages
wait_for_messages
echo "Kafka Setup complete"
