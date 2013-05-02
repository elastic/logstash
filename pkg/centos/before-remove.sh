if [ $1 -eq 0 ]; then
  /sbin/service logstash stop >/dev/null 2>&1 || true
  /sbin/chkconfig --del logstash
  if getent passwd logstash >/dev/null ; then
    userdel logstash
  fi

  if getent group logstash > /dev/null ; then
    groupdel logstash
  fi
fi
