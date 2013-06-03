#!/bin/sh

# create logstash user and group
if ! getent passwd logstash >/dev/null; then
  useradd -r -U -m -d /opt/logstash \
  -s /sbin/nologin -c "logstash" logstash
fi
