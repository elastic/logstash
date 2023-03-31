#!/bin/sh

chown -R root:root /usr/share/logstash
chown -R logstash /var/log/logstash
chown logstash:logstash /var/lib/logstash
chmod 755 /etc/logstash
sed -i \
  -e 's|# path.logs:|path.logs: /var/log/logstash|' \
  -e 's|# path.data:|path.data: /var/lib/logstash|' \
  /etc/logstash/logstash.yml
chmod 600 /etc/logstash/startup.options
chmod 600 /etc/default/logstash

# Starting from systemd 229, TimeouStopSec supports using
# 'infinity' to disable not send a SIG Kill.
#
# Older versions need to use 0 instead.
systemd_version=$(dpkg-query --showformat='${Version}' --show systemd 2> /dev/null)
if  [ -n $systemd_version ] && dpkg --compare-versions "$systemd_version" lt 229 ; then
    sed -i \
      -e "s/^TimeoutStopSec=infinity/TimeoutStopSec=0/" \
      /lib/systemd/system/logstash.service || true
else
    # Ensure's an upgraded system has the right setting, if it
    # wasn't automatically replaced by the OS.
    sed -i \
      -e "s/^TimeoutStopSec=0/TimeoutStopSec=infinity/" \
      /lib/systemd/system/logstash.service || true
fi
