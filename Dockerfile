FROM ubuntu:xenial

RUN apt-get update && \
    apt-get dist-upgrade && \
    apt-get install -y zlib1g-dev build-essential git curl libssl-dev libreadline-dev libyaml-dev  \
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

RUN git clone https://github.com/sstephenson/rbenv.git .rbenv && \
    git clone https://github.com/sstephenson/ruby-build.git .rbenv/plugins/ruby-build && \
    echo 'export PATH=/home/logstash/.rbenv/bin:$PATH' >> /home/logstash/.bashrc

ENV PATH "/home/logstash/.rbenv/bin:$PATH"

RUN echo 'eval "$(rbenv init -)"' >> .bashrc && \
    rbenv install jruby-9.1.12.0 && \
    rbenv global jruby-9.1.12.0 && \
    bash -i -c 'gem install bundler' && \
    rbenv local jruby-9.1.12.0 && \
    mkdir -p /opt/logstash/data

ADD gradlew /opt/logstash/gradlew
ADD gradle/wrapper /opt/logstash/gradle/wrapper
RUN /opt/logstash/gradlew wrapper

ADD versions.yml /opt/logstash/versions.yml
ADD LICENSE /opt/logstash/LICENSE
ADD CONTRIBUTORS /opt/logstash/CONTRIBUTORS
ADD NOTICE.TXT /opt/logstash/NOTICE.TXT
ADD Gemfile /opt/logstash/Gemfile
ADD Rakefile /opt/logstash/Rakefile
ADD build.gradle /opt/logstash/build.gradle
ADD rakelib /opt/logstash/rakelib
ADD config /opt/logstash/config
ADD spec /opt/logstash/spec
ADD lib /opt/logstash/lib
ADD pkg /opt/logstash/pkg
ADD tools /opt/logstash/tools
ADD logstash-core /opt/logstash/logstash-core
ADD logstash-core-plugin-api /opt/logstash/logstash-core-plugin-api
ADD bin /opt/logstash/bin
ADD modules /opt/logstash/modules
ADD CHANGELOG.md /opt/logstash/CHANGELOG.md
ADD settings.gradle /opt/logstash/settings.gradle

USER root
RUN rm -rf build && \
    mkdir -p build && \
    chown -R logstash:logstash /opt/logstash
USER logstash
WORKDIR /opt/logstash
RUN bash -i -c 'rake compile:all && rake artifact:tar && cd build && tar -xzf logstash-*.tar.gz'

USER root
ADD ci /opt/logstash/ci
ADD qa /opt/logstash/qa
RUN chown -R logstash:logstash /opt/logstash/ci /opt/logstash/qa

USER logstash
RUN bash -i -c 'cd qa/integration && bundle install'

