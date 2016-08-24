#!/bin/bash
set -ex
current_dir="$(dirname "$0")"
HOW_DATA_SET_URL=https://s3.amazonaws.com/data.elasticsearch.org/logstash/logs.gz

if [ ! -f ${current_dir}/how.input ]; then
  curl -sL $HOW_DATA_SET_URL > ${current_dir}/logs.gz
  gunzip ${current_dir}/logs.gz
  mv ${current_dir}/logs ${current_dir}/how.input
fi