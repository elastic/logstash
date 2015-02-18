#!/usr/bin/env bash

##
# Keep in mind to run ci/ci_setup.sh if you need to setup/clean up your environment before
# running the test suites here.
##

SELECTED_TEST_SUITE=$1

if [[ $SELECTED_TEST_SUITE == $"all" ]]; then
  echo "Running all plugins tests"
  rake plugin:install-all   # Install all plugins, using the file at tools/Gemfile.plugins.all
  rake vendor:append_development_dependencies\[tools/Gemfile.plugins.all\] # Append development dependencies to run the test
  rake plugin:install-all   # Install previously appended development dependencies

  #Run the specs test from all previously installed logstash plugins
  ./bin/logstash rspec --order rand vendor/bundle/jruby/1.9/gems/logstash-*/spec/{input,filter,codec,output}s/*_spec.rb
else
  echo "Running core tests"
  rake test:prep # setup the necessary plugins and dependencies for testing
  # Execute the test
  ./bin/logstash rspec --order rand --format CI::Reporter::RSpec spec/**/*_spec.rb spec/*_spec.rb
fi
