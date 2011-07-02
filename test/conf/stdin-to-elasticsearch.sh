#!/bin/sh

if [ -z "$1" ] ; then
  echo "Usage: $0 <command>"

  echo "Example: $0 java -jar logstash-1.0.12.jar"
  exit 1
fi

output='output { elasticsearch { embedded => true } } '
"$@" agent -e "$output"
