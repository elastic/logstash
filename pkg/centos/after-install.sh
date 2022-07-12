chown -R root:root /usr/share/logstash
chown -R logstash /var/log/logstash
chown logstash:logstash /var/lib/logstash
sed -i \
  -e 's|# path.logs:|path.logs: /var/log/logstash|' \
  -e 's|# path.data:|path.data: /var/lib/logstash|' \
  /etc/logstash/logstash.yml
chmod 600 /etc/logstash/startup.options
chmod 600 /etc/default/logstash
# Ensure the init script is picked up by systemd
systemctl daemon-reload 2> /dev/null || true
