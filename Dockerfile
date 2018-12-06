FROM ubuntu:xenial

RUN apt-get update && \
    apt-get install -y zlib1g-dev build-essential vim rake git curl libssl-dev libreadline-dev libyaml-dev  \
      libxml2-dev libxslt-dev openjdk-8-jdk-headless curl iputils-ping netcat && \
    apt-get clean

WORKDIR /root

RUN adduser --disabled-password --gecos "" --home /home/logstash logstash && \
    mkdir -p /usr/local/share/ruby-build && \
    mkdir -p /opt/logstash && \
    mkdir -p /mnt/host && \
    chown logstash:logstash /opt/logstash

USER logstash
WORKDIR /home/logstash

# used by the purge policy
LABEL retention="keep"

ADD gradlew /opt/logstash/gradlew
ADD gradle/wrapper /opt/logstash/gradle/wrapper
ADD buildSrc /opt/logstash/buildSrc
RUN /opt/logstash/gradlew wrapper

ADD versions.yml /opt/logstash/versions.yml
ADD LICENSE.txt /opt/logstash/LICENSE.txt
ADD NOTICE.TXT /opt/logstash/NOTICE.TXT
ADD licenses /opt/logstash/licenses
ADD CONTRIBUTORS /opt/logstash/CONTRIBUTORS
ADD Gemfile.template /opt/logstash/Gemfile.template
ADD Rakefile /opt/logstash/Rakefile
ADD build.gradle /opt/logstash/build.gradle
ADD rakelib /opt/logstash/rakelib
ADD config /opt/logstash/config
ADD spec /opt/logstash/spec
ADD qa /opt/logstash/qa
ADD lib /opt/logstash/lib
ADD pkg /opt/logstash/pkg
ADD tools /opt/logstash/tools
ADD logstash-core /opt/logstash/logstash-core
ADD logstash-core-plugin-api /opt/logstash/logstash-core-plugin-api
ADD bin /opt/logstash/bin
ADD modules /opt/logstash/modules
ADD x-pack /opt/logstash/x-pack
ADD ci /opt/logstash/ci
ADD settings.gradle /opt/logstash/settings.gradle

USER root
RUN rm -rf build && \
    mkdir -p build && \
    chown -R logstash:logstash /opt/logstash
USER logstash
WORKDIR /opt/logstash

LABEL retention="prune"

