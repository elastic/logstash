#!/bin/bash -ie

# Since we are using the system jruby, we need to make sure our jvm process
# uses at least 1g of memory, If we don't do this we can get OOM issues when
# installing gems. See https://github.com/elastic/logstash/issues/5179
export JRUBY_OPTS="-J-Xmx1g"

export SPEC_OPTS="--order rand --format documentation"

if [[ ! -d "build" ]]; then
  mkdir build
fi
rm -rf build/*
echo "Building tar"
rake artifact:tar
cd build
tar xf *.tar.gz

cd ../qa/integration
echo "Installing test dependencies"
bundle install

#exit early if only setting up
[[ $1 = "setup" ]] && exit 0

echo "Running integration tests $@"
rspec --tag ~offline $@
rspec --tag offline $@

#Note - ensure that the -e flag is set to properly set the $? status if any command fails