## Logstash Integration Tests

These set of tests are full integration tests as in they start LS from a binary, run config using `-e` and can use any external services

## Setting up

* From LS_HOME source directory, run `rake artifact:tar`
* `cd build`
* Unzip the recently built file: `tar xvf logstash-<version>.tar.gz`

* `bundle install`
This will install test specific dependency gems.
* You are ready to run any tests
* `rspec specs/es_output_how_spec.rb`
