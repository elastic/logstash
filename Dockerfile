FROM ubuntu:bionic

RUN apt-get update && \
    apt-get install -y zlib1g-dev build-essential vim rake git curl libssl-dev libreadline-dev libyaml-dev  \
      libxml2-dev libxslt-dev openjdk-11-jdk-headless curl iputils-ping netcat && \
    apt-get clean

WORKDIR /root

RUN adduser --disabled-password --gecos "" --home /home/logstash logstash && \
    mkdir -p /usr/local/share/ruby-build && \
    mkdir -p /opt/logstash && \
    mkdir -p /opt/logstash/data && \
    mkdir -p /mnt/host && \
    chown logstash:logstash /opt/logstash

USER logstash
WORKDIR /home/logstash

# used by the purge policy
LABEL retention="keep"

# Setup gradle wrapper. When running any `gradle` command, a `settings.gradle` is expected (and will soon be required).
# This section adds the gradle wrapper, `settings.gradle` and sets the permissions (setting the user to root for `chown`
# and working directory to allow this and then reverts back to the previous working directory and user.
COPY --chown=logstash:logstash gradlew /opt/logstash/gradlew
COPY --chown=logstash:logstash gradle/wrapper /opt/logstash/gradle/wrapper
COPY --chown=logstash:logstash settings.gradle /opt/logstash/settings.gradle
WORKDIR /opt/logstash
RUN for iter in `seq 1 10`; do ./gradlew wrapper --warning-mode all && exit_code=0 && break || exit_code=$? && echo "gradlew error: retry $iter in 10s" && sleep 10; done; exit $exit_code
WORKDIR /home/logstash

ADD versions.yml /opt/logstash/versions.yml
ADD LICENSE.txt /opt/logstash/LICENSE.txt
ADD NOTICE.TXT /opt/logstash/NOTICE.TXT
ADD licenses /opt/logstash/licenses
ADD CONTRIBUTORS /opt/logstash/CONTRIBUTORS
ADD Gemfile.template Gemfile.jruby-2.6.lock.* /opt/logstash/
ADD Rakefile /opt/logstash/Rakefile
ADD build.gradle /opt/logstash/build.gradle
ADD rubyUtils.gradle /opt/logstash/rubyUtils.gradle
ADD rakelib /opt/logstash/rakelib
ADD config /opt/logstash/config
ADD spec /opt/logstash/spec
ADD qa /opt/logstash/qa
ADD lib /opt/logstash/lib
ADD pkg /opt/logstash/pkg
ADD buildSrc /opt/logstash/buildSrc
ADD tools /opt/logstash/tools
ADD logstash-core /opt/logstash/logstash-core
ADD logstash-core-plugin-api /opt/logstash/logstash-core-plugin-api
ADD bin /opt/logstash/bin
ADD modules /opt/logstash/modules
ADD x-pack /opt/logstash/x-pack
ADD ci /opt/logstash/ci

USER root
RUN rm -rf build && \
    mkdir -p build && \
    chown -R logstash:logstash /opt/logstash
USER logstash
WORKDIR /opt/logstash

LABEL retention="prune"