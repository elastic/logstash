#logstash-base image, use ci/docker_update_base_image.sh to push updates
FROM ubuntu:bionic

RUN apt-get update && \
    apt-get install -y zlib1g-dev build-essential vim rake git curl libssl-dev libreadline-dev libyaml-dev  \
      libxml2-dev libxslt-dev openjdk-11-jdk-headless curl iputils-ping netcat && \
    apt-get clean

WORKDIR /root

RUN adduser --disabled-password --gecos "" --home /home/logstash logstash && \
    mkdir -p /usr/local/share/ruby-build && \
    mkdir -p /opt/logstash && \
    mkdir -p /mnt/host && \
    chown logstash:logstash /opt/logstash

USER logstash
WORKDIR /home/logstash
RUN mkdir -p /opt/logstash/data

# used by the purge policy
LABEL retention="keep"
