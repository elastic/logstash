#!/bin/sh

# create logstash group
if ! getent group logstash >/dev/null; then
  groupadd -r logstash
fi

# create logstash user
if ! getent passwd logstash >/dev/null; then
  useradd -M -r -g logstash -d /usr/share/logstash \
    -s /usr/sbin/nologin -c "LogStash Service User" logstash
fi
