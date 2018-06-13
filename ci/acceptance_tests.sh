#!/usr/bin/env bash
set -e
set -x

# Since we are using the system jruby, we need to make sure our jvm process
# uses at least 1g of memory, If we don't do this we can get OOM issues when
# installing gems. See https://github.com/elastic/logstash/issues/5179
export JRUBY_OPTS="-J-Xmx1g"
export GRADLE_OPTS="-Xmx2g -Dorg.gradle.daemon=false -Dorg.gradle.logging.level=info -Dfile.encoding=UTF-8"
export OSS=true

SELECTED_TEST_SUITE=$1

# The acceptance test in our CI infrastructure doesn't clear the workspace between run
# this mean the lock of the Gemfile can be sticky from a previous run, before generating any package
# we will clear them out to make sure we use the latest version of theses files
# If we don't do this we will run into gem Conflict error.
[ -f Gemfile ] && rm Gemfile
[ -f Gemfile.lock ] && rm Gemfile.lock

# When running these tests in a Jenkins matrix, in parallel, once one Vagrant job is done, the Jenkins ProcessTreeKiller will kill any other Vagrant processes with the same
# BUILD_ID unless you set this magic flag:  https://wiki.jenkins.io/display/JENKINS/ProcessTreeKiller
export BUILD_ID=dontKillMe

LS_HOME="$PWD"
QA_DIR="$PWD/qa"

# Always run the halt, even if the test times out or an exit is sent
cleanup() {
  cd $QA_DIR
  bundle exec rake qa:vm:halt
}
trap cleanup EXIT

# Cleanup any stale VMs from old jobs first

cd $QA_DIR
bundle exec rake qa:vm:halt

if [[ $SELECTED_TEST_SUITE == $"redhat" ]]; then
  echo "Generating the RPM, make sure you start with a clean environment before generating other packages."
  cd $LS_HOME
  rake artifact:rpm
  echo "Acceptance: Installing dependencies"
  cd $QA_DIR
  bundle install

  echo "Acceptance: Running the tests"
  bundle exec rake qa:vm:setup["redhat"]
  bundle exec rake qa:vm:ssh_config
  bundle exec rake qa:acceptance:redhat
  bundle exec rake qa:vm:halt["redhat"]
elif [[ $SELECTED_TEST_SUITE == $"debian" ]]; then
  echo "Generating the DEB, make sure you start with a clean environment before generating other packages."
  cd $LS_HOME
  rake artifact:deb
  echo "Acceptance: Installing dependencies"
  cd $QA_DIR
  bundle install

  echo "Acceptance: Running the tests"
  bundle exec rake qa:vm:setup["debian"]
  bundle exec rake qa:vm:ssh_config
  bundle exec rake qa:acceptance:debian
  bundle exec rake qa:vm:halt["debian"]
elif [[ $SELECTED_TEST_SUITE == $"all" ]]; then
  echo "Building Logstash artifacts"
  cd $LS_HOME
  rake artifact:all

  echo "Acceptance: Installing dependencies"
  cd $QA_DIR
  bundle install

  echo "Acceptance: Running the tests"
  bundle exec rake qa:vm:setup
  bundle exec rake qa:vm:ssh_config
  bundle exec rake qa:acceptance:all
  bundle exec rake qa:vm:halt
fi


