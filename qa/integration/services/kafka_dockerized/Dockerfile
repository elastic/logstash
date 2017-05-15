FROM debian:stretch

ENV KAFKA_HOME /kafka
ENV KAFKA_LOGS_DIR="/kafka-logs"
ENV KAFKA_VERSION 0.10.2.1
ENV _JAVA_OPTIONS "-Djava.net.preferIPv4Stack=true"
ENV TERM=linux

RUN apt-get update && apt-get install -y curl openjdk-8-jre-headless netcat

RUN mkdir -p ${KAFKA_LOGS_DIR} && mkdir -p ${KAFKA_HOME} && curl -s -o $INSTALL_DIR/kafka.tgz \
    "http://ftp.wayne.edu/apache/kafka/${KAFKA_VERSION}/kafka_2.11-${KAFKA_VERSION}.tgz" && \
    tar xzf ${INSTALL_DIR}/kafka.tgz -C ${KAFKA_HOME} --strip-components 1
    
ADD run.sh /run.sh

EXPOSE 9092
EXPOSE 2181
