#!/bin/sh
set -e

# Since we are using the system jruby, we need to make sure our jvm process
# uses at least 1g of memory, If we don't do this we can get OOM issues when
# installing gems. See https://github.com/elastic/logstash/issues/5179
export JRUBY_OPTS="-J-Xmx1g"

echo "Running integration tests from qa/integration"
if [[ ! -d "build" ]]; then
  mkdir build
fi  
rm -rf build/*  
echo "Building logstash tar file in build/"
rake artifact:tar
cd build
echo "Extracting logstash tar file in build/"
tar xf *.tar.gz
cd ../qa/integration
# to install test dependencies
bundle install
# runs all tests
rspec
