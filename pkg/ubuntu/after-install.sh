#!/bin/sh

chown -R logstash:logstash /opt/logstash
chown logstash /var/log/logstash
chown logstash:logstash /var/lib/logstash

ln -sf /opt/logstash/logstash.jar /var/lib/logstash/logstash.jar
