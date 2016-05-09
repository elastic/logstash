#!/bin/sh

chown -R logstash:logstash /usr/share/logstash
chown logstash /var/log/logstash
chown logstash:logstash /var/lib/logstash
chmod 755 /etc/logstash
chmod 0644 /etc/logrotate.d/logstash
/usr/share/logstash/bin/system-install /etc/logstash/startup.options
