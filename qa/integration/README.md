## Logstash Integration Tests aka RATS

These set of tests are full integration tests as in: they can start LS from a binary, run configs using `-e` and can use any external services like Kafka, ES and S3. This framework is hybrid -- a combination of bash scripts (to mainly setup services), Ruby service files, and RSpec. All test assertions are done in RSpec.

No VMs, all tests run locally.

## Dependencies
* An existing Logstash binary, defaults to `LS_HOME/build/logstash-<version>`
* `rspec`

## Preparing a test run

1. If you already have a LS binary in `LS_HOME/build/logstash-<version>`, skip to step 5
2. From Logstash git source directory or `LS_HOME` run `rake artifact:tar` to build a package
2. Untar the newly built package
3. `cd build`
4. `tar xvf logstash-<version>.tar.gz`
5. `cd LS_HOME/qa/integration`
6. `bundle install`: This will install test dependency gems.

You are now ready to run any tests from `qa/integration`.
* Run all tests: `rspec specs/*`
* Run single test: `rspec specs/es_output_how_spec.rb`

### Directory Layout

* `fixtures`: In this dir you will test settings in form of `test_name.yml`. Here you specify services to run, LS config, test specific scripts ala `.travis.yml`
* `services`: This dir has bash scripts that download and bootstrap binaries for services. This is where services like ES will be downloaded and run from. Service can have 3 files: `<service>_setup.sh`, `<service>_teardown.sh` and `<service>`.rb. The bash scripts deal with downloading and bootstrapping, but the ruby source will trigger them from the test as a shell out (using backticks). The tests are blocked until the setup/teardown completes. For example, Elasticsearch service has `elasticsearch_setup.sh`, `elasticsearch_teardown.sh` and `elasticsearch.rb`. The service name in yml is "elasticsearch".
* `framework`: Test framework source code.
* `specs`: Rspec tests that use services and validates stuff

### Adding a new test

1. Creating a new test -- lets use as example. Call it "test_file_input" which brings up LS to read from a file and assert file contents (file output) were as expected.
2. You'll have to create a yml file in `fixtures` called `test_file_input_spec.yml`. Here you define any external services you need and any LS config.
3. Create a corresponding `test_file_input_spec.rb` in `specs` folder and use the `fixtures` object to get all services, config etc. The `.yml` and rspec file has to be the same name for the settings to be picked up. You can start LS inside the tests and assume all external services have already been started.
4. Write rspec code to validate.

## Future Improvements

1. Perform setup and teardown from Ruby and get rid of bash files altogether.
