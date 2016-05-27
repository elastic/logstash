#!/bin/sh

chown -R logstash:logstash /usr/share/logstash
chown logstash /var/log/logstash
chown logstash:logstash /var/lib/logstash
chmod 755 /etc/logstash
chmod 0644 /etc/logrotate.d/logstash
sed -i \
  -e 's|# path.config:|path.config: /etc/logstash/conf.d|' \
  -e 's|# path.log:|path.log: /var/log/logstash/logstash.log|' \
  /etc/logstash/logstash.yml
/usr/share/logstash/bin/system-install /etc/logstash/startup.options
