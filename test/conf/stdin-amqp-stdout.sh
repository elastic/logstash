#!/bin/sh

if [ -z "$1" ] ; then
  echo "Usage: $0 <command>"

  echo "Example: $0 java -jar logstash-1.0.12.jar"
  exit 1
fi

output='
  output { 
    amqp { 
      host => "localhost"
      exchange_type => "fanout"
      name => "logstash"
    }
  } '

input='
  input {
    amqp {
      type => "amqpexample"
      host => "localhost"
      exchange_type => "fanout"
      name => "logstash"
    }
  } '

"$@" agent -e "$output" -- agent -e "$input"
#"$@" agent -e "$output"
#"$@" agent -e "$input"
