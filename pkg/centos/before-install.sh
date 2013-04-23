# create logstash group
if ! getent group logstash >/dev/null; then
  groupadd -r logstash
fi

# create logstash user
if ! getent passwd logstash >/dev/null; then
  useradd -r -g logstash -d /opt/logstash \
    -s /sbin/nologin -c "logstash" logstash
fi
