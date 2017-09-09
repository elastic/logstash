#!/bin/bash -ie

# Since we are using the system jruby, we need to make sure our jvm process
# uses at least 1g of memory, If we don't do this we can get OOM issues when
# installing gems. See https://github.com/elastic/logstash/issues/5179
export JRUBY_OPTS="-J-Xmx1g"

export SPEC_OPTS="--order rand --format documentation"

SELECTED_TEST_SUITE=$1

if [[ $SELECTED_TEST_SUITE == $"core-fail-fast" ]]; then
  echo "Running core-fail-fast tests"
  rake test:install-core    # Install core dependencies for testing.
  rake test:core-fail-fast  # Run core tests
elif [[ $SELECTED_TEST_SUITE == $"all" ]]; then
  echo "Running all plugins tests"
  rake test:install-all     # Install all plugins in this logstash instance, including development dependencies
  rake test:plugins         # Run all plugins tests
else
  echo "Running test:install-core"
  rake test:install-core    # Install core dependencies for testing.
  echo "Running test:core"
  rake test:core            # Run core tests
fi
