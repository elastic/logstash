#!/usr/bin/env bash
set -e

output_dir=$1

if [[ -z $output_dir ]]; then
  echo "Docs will be generated in default directory in LS_HOME/build/docs"
else
  echo "Docs will be generated in directory $output_dir"
fi

# Since we are using the system jruby, we need to make sure our jvm process
# uses at least 1g of memory, If we don't do this we can get OOM issues when
# installing gems. See https://github.com/elastic/logstash/issues/5179
export JRUBY_OPTS="-J-Xmx1g"

mkdir -p build/docs
rm -rf build/docs/*

grep -q -F "logstash-docgen" Gemfile || echo 'gem "logstash-docgen", :path => "./tools/logstash-docgen"' >> Gemfile
rake bootstrap
rake test:install-core
rake docs:generate-plugins[$output_dir]
