# create logstash group
if ! getent group logstash >/dev/null; then
  groupadd -r logstash
fi

# create logstash user
if ! getent passwd logstash >/dev/null; then
  useradd -r -g logstash -d /usr/share/logstash \
    -s /sbin/nologin -c "logstash" logstash
fi

# Handle upgrade
## Check if old service unit exists and remove it
if [ -f /etc/systemd/system/logstash.service ]; then
  rm -rf /etc/systemd/system/logstash.service || true
fi

## Check if startup.options file exists and remote it
if [ -f /etc/logstash/startup.options ]; then
  rm -rf /etc/logstash/startup.options || true
fi
