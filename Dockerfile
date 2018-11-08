FROM container-registry-test.elastic.co/logstash-test/logstash-base:latest

RUN ln -s /tmp/vendor /opt/logstash/vendor

ADD gradlew /opt/logstash/gradlew
ADD gradle/wrapper /opt/logstash/gradle/wrapper
ADD buildSrc /opt/logstash/buildSrc
RUN /opt/logstash/gradlew wrapper

ADD versions.yml /opt/logstash/versions.yml
ADD LICENSE.txt /opt/logstash/LICENSE.txt
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

