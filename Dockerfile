FROM ubuntu:latest

RUN apt-get update && \
    apt-get dist-upgrade && \
    apt-get install -y zlib1g-dev build-essential git curl libssl-dev libreadline-dev libyaml-dev  \
      libxml2-dev libxslt-dev openjdk-8-jdk-headless && \
    apt-get clean

WORKDIR /root

RUN adduser --disabled-password --gecos "" --home /home/logstash logstash && \
    mkdir -p /usr/local/share/ruby-build

USER logstash
WORKDIR /home/logstash

RUN git clone https://github.com/sstephenson/rbenv.git .rbenv && \
    git clone https://github.com/sstephenson/ruby-build.git .rbenv/plugins/ruby-build

ENV PATH "/home/logstash/.rbenv/bin:$PATH"

RUN echo 'eval "$(rbenv init -)"' >> .bashrc && \
    rbenv install jruby-9.1.12.0 && \
    rbenv global jruby-9.1.12.0

RUN rbenv local jruby-9.1.12.0
RUN ruby -v

RUN gem install bundler rake

ADD . /home/logstash/logstash

WORKDIR /home/logstash/logstash

RUN rake bootstrap && rake test:install-core