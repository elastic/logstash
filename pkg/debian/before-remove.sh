#!/bin/sh

if [ $1 == "remove" ]; then
  /etc/init.d/logstash > /dev/null 2>&1 || true

  if getent passwd logstash >/dev/null ; then
    userdel logstash
  fi

  if getent group logstash > /dev/null ; then
    groupdel logstash
  fi

  if [ -d "/home/logstash" ] ; then
    rm -rf /home/logstash
  fi
fi
