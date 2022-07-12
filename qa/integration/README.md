## Logstash Integration Tests aka RATS

These test sets are full integration tests. They can: 

* start Logstash from a binary, 
* run configs using `-e`, and 
* use external services such as Kafka, Elasticsearch, and Beats.

This framework is hybrid -- a combination of bash scripts (to mainly setup services), Ruby service files, and RSpec. All test assertions are done in RSpec.

## Environment setup

### Directory Layout

* `fixtures`: Specify services to run, Logstash config, and test specific scripts ala `.travis.yml`. You test settings in form of `test_name.yml`. 
* `services`: This directory has bash scripts that download and bootstrap binaries for services. This is where services like Elasticsearch will be downloaded and run. Service can have 3 files: `<service>_setup.sh`, `<service>_teardown.sh` and `<service>`.rb. The bash scripts deal with downloading and bootstrapping, but the ruby source will trigger them from the test as a shell out (using backticks). The tests are blocked until the setup/teardown completes. For example, Elasticsearch service has `elasticsearch_setup.sh`, `elasticsearch_teardown.sh` and `elasticsearch.rb`. The service name in yml is "elasticsearch".
* `framework`: Test framework source code.
* `specs`: Rspec tests that use services and validates stuff

### Setup Java

The integration test scripts use `gradle` to run the tests.
Gradle requires a valid version of Java either on the system path, or specified using the `JAVA_HOME` environment variable pointing to the location of a valid JDK.

To run integration tests using a different version of Java, set the `BUILD_JAVA_HOME` environment variable to the location of the JDK that you wish to test with.
## Testing on Mac/Linux

### Dependencies 
* `JRuby`
* `rspec` 
* `rake`
* `bundler`

### Running integration tests locally (Mac/Linux) 
Run tests from the Logstash root directory.

* Run all tests: 

  `ci/integration_tests.sh`
  
* Run a single test: 

  `ci/integration_tests.sh specs/es_output_how_spec.rb`
  
* Debug tests: 
  ```
  ci/integration_tests.sh setup 
  cd qa/integration
  bundle exec rspec specs/es_output_how_spec.rb (single test)
  bundle exec rspec specs/*  (all tests)
  ```
  
## Testing with Docker 

### Dependencies 
* `Docker`

### Running integration tests locally using Docker 

Run tests from the Logstash root directory.

* Run all tests:

  ```
  docker build  -t logstash-integration-tests .
  docker run -it --rm logstash-integration-tests ci/integration_tests.sh 
  ```
  
* Run a single test: 
```
docker build  -t logstash-integration-tests .
docker run -it --rm logstash-integration-tests ci/integration_tests.sh specs/es_output_how_spec.rb
``` 

* Debug tests:
```
(Mac/Linux) docker ps --all -q -f status=exited | xargs docker rm  
(Windows) `docker ps -a` and take note of any exited containers, then `docker rm <container-id>`
docker build -t logstash-integration-tests . 
docker run -d --name debug logstash-integration-tests tail -f /dev/null
docker exec -it debug ci/integration_tests.sh setup 
docker exec -it debug bash
cd qa/integration
bundle exec rspec specs/es_output_how_spec.rb
exit
docker kill debug
docker rm debug
```

### Docker clean up (Mac/Linux)

WARNING: Docker cleanup removes all images and containers except for the `logstash-base` container!

* `ci/docker_prune.sh`

## Testing on Windows

The integration tests should be run from MacOS or Linux.  However, the tests can be run locally within Docker on Windows.


## Adding a new test

1. Creating a new test -- lets use as example. Call it "test_file_input" which brings up LS to read from a file and assert file contents (file output) were as expected.
2. You'll have to create a yml file in `fixtures` called `test_file_input_spec.yml`. Here you define any external services you need and any LS config.
3. Create a corresponding `test_file_input_spec.rb` in `specs` folder and use the `fixtures` object to get all services, config etc. The `.yml` and rspec file has to be the same name for the settings to be picked up. You can start LS inside the tests and assume all external services have already been started.
4. Write rspec code to validate.


