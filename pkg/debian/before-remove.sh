#!/bin/sh

if [ $1 = "remove" ]; then
  service logstash stop >/dev/null 2>&1 || true

  if getent passwd logstash >/dev/null ; then
    userdel logstash
  fi

  if getent group logstash >/dev/null ; then
    groupdel logstash
  fi
fi
