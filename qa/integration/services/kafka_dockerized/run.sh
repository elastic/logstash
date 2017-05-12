#!/bin/bash

KAFKA_TOPIC=logstash_topic_plain

wait_for_port() {
    count=20
    port=$1
    while ! nc -z localhost $port && [[ $count -ne 0 ]]; do
        count=$(( $count - 1 ))
        [[ $count -eq 0 ]] && return 1
        sleep 0.5
    done
    # just in case, one more time
    nc -z localhost $port
}

echo "Starting ZooKeeper"
${KAFKA_HOME}/bin/zookeeper-server-start.sh ${KAFKA_HOME}/config/zookeeper.properties &
wait_for_port 2181
echo "Starting Kafka broker"
mkdir -p ${KAFKA_LOGS_DIR}
${KAFKA_HOME}/bin/kafka-server-start.sh ${KAFKA_HOME}/config/server.properties \
    --override delete.topic.enable=true --override advertised.host.name=127.0.0.1 \
    --override logs.dir=${KAFKA_LOGS_DIR} --override log.flush.interval.ms=200 &

wait_for_port 9092

${KAFKA_HOME}/bin/kafka-topics.sh --create --partitions 1 --replication-factor 1 --topic ${KAFKA_TOPIC} --zookeeper 127.0.0.1:2181

${KAFKA_HOME}/bin/kafka-console-producer.sh --topic ${KAFKA_TOPIC} --broker-list 127.0.0.1:9092 < /how_sample.input

echo "Kafka load status code $?"

tail -f /dev/null
