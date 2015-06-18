#!/usr/bin/env bash

##
# Keep in mind to run ci/ci_setup.sh if you need to setup/clean up your environment before
# running the test suites here.
##

SELECTED_TEST_SUITE=$1

if [[ $SELECTED_TEST_SUITE == $"core-fail-fast" ]]; then
  echo "Running core-fail-fast tests"
  rake test:install-core    # Install core dependencies for testing.
  rake test:core-fail-fast  # Run core tests
elif [[ $SELECTED_TEST_SUITE == $"all" ]]; then
  echo "Running all plugins tests"
  rake test:install-all     # Install all plugins in this logstash instance, including development dependencies
  rake test:plugins         # Run all plugins tests
elif [[ $SELECTED_TEST_SUITE == "license" ]]; then
  echo "License generation, install core"
  rake test:install-core
  echo "License generation, generating dependency license information"
  rake license
else
  echo "Running core tests"
  rake test:install-core    # Install core dependencies for testing.
  rake test:core            # Run core tests
fi
