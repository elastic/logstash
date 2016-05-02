#!/bin/sh
set -e

# Since we are using the system jruby, we need to make sure our jvm process
# uses at least 1g of memory, If we don't do this we can get OOM issues when
# installing gems. See https://github.com/elastic/logstash/issues/5179
export JRUBY_OPTS="-J-Xmx1g"

SELECTED_TEST_SUITE=$1

if [[ $SELECTED_TEST_SUITE == $"centos" ]]; then
  echo "Generating the RPM, make sure you start with a clean environment before generating other packages."
  rake artifact:rpm
  echo "Acceptance: Installing dependencies"
  cd qa
  bundle install

  echo "Acceptance: Running the tests"
  bundle exec rake test:setup
  bundle exec rake test:ssh_config
  bundle exec rake test:acceptance:centos
elif [[ $SELECTED_TEST_SUITE == $"debian" ]]; then
  echo "Generating the DEB, make sure you start with a clean environment before generating other packages."
  rake artifact:deb
  echo "Acceptance: Installing dependencies"
  cd qa
  bundle install

  echo "Acceptance: Running the tests"
  bundle exec rake test:setup
  bundle exec rake test:ssh_config
  bundle exec rake test:acceptance:debian
elif [[ $SELECTED_TEST_SUITE == $"all" ]]; then
  echo "Building Logstash artifacts"
  rake artifact:all

  echo "Acceptance: Installing dependencies"
  cd qa
  bundle install

  echo "Acceptance: Running the tests"
  bundle exec rake test:setup
  bundle exec rake test:ssh_config
  bundle exec rake test:acceptance:all
  cd ..
fi
