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

COPY versions.yml /opt/logstash/versions.yml
COPY LICENSE.txt /opt/logstash/LICENSE.txt
COPY NOTICE.TXT /opt/logstash/NOTICE.TXT
COPY licenses /opt/logstash/licenses
COPY CONTRIBUTORS /opt/logstash/CONTRIBUTORS
COPY Gemfile.template Gemfile.jruby-3.1.lock.* /opt/logstash/
COPY Rakefile /opt/logstash/Rakefile
COPY build.gradle /opt/logstash/build.gradle
COPY rubyUtils.gradle /opt/logstash/rubyUtils.gradle
COPY rakelib /opt/logstash/rakelib
COPY config /opt/logstash/config
COPY spec /opt/logstash/spec
COPY qa /opt/logstash/qa
COPY lib /opt/logstash/lib
COPY pkg /opt/logstash/pkg
COPY buildSrc /opt/logstash/buildSrc
COPY tools /opt/logstash/tools
COPY logstash-core /opt/logstash/logstash-core
COPY logstash-core-plugin-api /opt/logstash/logstash-core-plugin-api
COPY bin /opt/logstash/bin
COPY modules /opt/logstash/modules
COPY x-pack /opt/logstash/x-pack
COPY ci /opt/logstash/ci

USER root
RUN rm -rf build && \
    mkdir -p build && \
    chown -R logstash:logstash /opt/logstash
USER logstash
WORKDIR /opt/logstash

LABEL retention="prune"