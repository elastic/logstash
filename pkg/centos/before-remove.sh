# CentOS/RHEL and SuSE
if [ $1 -eq 0 ]; then
  # Upstart
  if [ -r "/etc/init/logstash.conf" ]; then
    if [ -f "/sbin/stop" ]; then
      /sbin/stop logstash >/dev/null 2>&1 || true
    else
      /sbin/service logstash stop >/dev/null 2>&1 || true
    fi
    if [ -f "/etc/init/logstash.conf" ]; then
      rm /etc/init/logstash.conf
    fi
  # SYSV
  elif [ -r "/etc/init.d/logstash" ]; then
    /sbin/chkconfig --del logstash
    if [ -f "/etc/init.d/logstash" ]; then
      rm /etc/init.d/logstash
    fi
  # systemd
  else
    systemctl stop logstash >/dev/null 2>&1 || true
    if [ -f "/etc/systemd/system/logstash-prestart.sh" ]; then
      rm /etc/systemd/system/logstash-prestart.sh
    fi

    if [ -f "/etc/systemd/system/logstash.service" ]; then
      rm /etc/systemd/system/logstash.service
    fi
  fi
  if getent passwd logstash >/dev/null ; then
    userdel logstash
  fi

  if getent group logstash > /dev/null ; then
    groupdel logstash
  fi
fi
