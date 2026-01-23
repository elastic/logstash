#!/usr/bin/env bash
set -e
set -x

# Since we are using the system jruby, we need to make sure our jvm process
# uses at least 1g of memory, If we don't do this we can get OOM issues when
# installing gems. See https://github.com/elastic/logstash/issues/5179
export JRUBY_OPTS="-J-Xmx1g"
export GRADLE_OPTS="-Xmx4g -Dorg.gradle.console=plain -Dorg.gradle.daemon=false -Dorg.gradle.logging.level=info -Dfile.encoding=UTF-8"

# Use local artifacts for acceptance test Docker builds
export LOCAL_ARTIFACTS=true

if [ -n "$BUILD_JAVA_HOME" ]; then
  GRADLE_OPTS="$GRADLE_OPTS -Dorg.gradle.java.home=$BUILD_JAVA_HOME"
fi

# Can run either a specific flavor, or all flavors -
<<<<<<< HEAD
# eg `ci/acceptance_tests.sh oss` will run tests for open source container
#    `ci/acceptance_tests.sh full` will run tests for the default container
#    `ci/acceptance_tests.sh ubi8` will run tests for the ubi8 based container
#    `ci/acceptance_tests.sh wolfi` will run tests for the wolfi based container
#    `ci/acceptance_tests.sh` will run tests for all containers
=======
# eg `ci/docker_acceptance_tests.sh oss` will run tests for open source container
#    `ci/docker_acceptance_tests.sh full` will run tests for the default container
#    `ci/docker_acceptance_tests.sh wolfi` will run tests for the wolfi based container
#    `ci/docker_acceptance_tests.sh` will run tests for all containers
>>>>>>> 205d8ab78 (Consistent bundled jruby across all CI tasks (#18615))
SELECTED_TEST_SUITE=$1

# The acceptance test in our CI infrastructure doesn't clear the workspace between run
# this mean the lock of the Gemfile can be sticky from a previous run, before generating any package
# we will clear them out to make sure we use the latest version of theses files
# If we don't do this we will run into gem Conflict error.
[ -f Gemfile ] && rm Gemfile
[ -f Gemfile.lock ] && rm Gemfile.lock

if [[ $SELECTED_TEST_SUITE == "oss" ]]; then
  echo "--- Building and testing $SELECTED_TEST_SUITE docker images"
  ./gradlew runDockerOssTests
elif [[ $SELECTED_TEST_SUITE == "full" ]]; then
<<<<<<< HEAD
  echo "--- Building $SELECTED_TEST_SUITE docker images"
  cd $LS_HOME
  ./gradlew artifactDocker
  echo "--- Acceptance: Installing dependencies"
  cd $QA_DIR
  bundle install

  echo "--- Acceptance: Running the tests"
  bundle exec rspec docker/spec/full/*_spec.rb
elif [[ $SELECTED_TEST_SUITE == "ubi8" ]]; then
  echo "--- Building $SELECTED_TEST_SUITE docker images"
  cd $LS_HOME
  ./gradlew artifactDockerUbi8
  echo "--- Acceptance: Installing dependencies"
  cd $QA_DIR
  bundle install

  echo "--- Acceptance: Running the tests"
  bundle exec rspec docker/spec/ubi8/*_spec.rb
=======
  echo "--- Building and testing $SELECTED_TEST_SUITE docker images"
  ./gradlew runDockerFullTests
>>>>>>> 205d8ab78 (Consistent bundled jruby across all CI tasks (#18615))
elif [[ $SELECTED_TEST_SUITE == "wolfi" ]]; then
  echo "--- Building and testing $SELECTED_TEST_SUITE docker images"
  ./gradlew runDockerWolfiTests
elif [[ $SELECTED_TEST_SUITE == "ironbank" ]]; then
  echo "--- Building and testing $SELECTED_TEST_SUITE docker images"
  ./gradlew runDockerIronbankTests
else
  echo "--- Building and testing all docker images"
  ./gradlew runAllDockerTests
fi
