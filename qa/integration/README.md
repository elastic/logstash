## Logstash Integration Tests aka RATS

These set of tests are full integration tests as in: they can start LS from a binary, run configs using `-e` and can use any external services like Kafka, ES and S3. This framework is hybrid -- a combination of bash scripts (to mainly setup services), Ruby service files, and RSpec. All test assertions are done in RSpec.



## Running integration tests locally (Mac/Linux)

### Dependencies 
* `JRuby`
* `rspec` 
* `rake`
* `bundler`

From the Logstash root directory:

* Run all tests: `ci/integration_tests.sh`
* Run a single test: `ci/integration_tests.sh specs/es_output_how_spec.rb`
* Debug tests: 
```
ci/integration_tests.sh setup 
cd qa/integration
bundle exec rspec specs/es_output_how_spec.rb (single test)
bundle exec rspec specs/*  (all tests)
```
## Running integration tests locally via Docker 

### Dependencies 
* `Docker`

From the Logstash root directory:

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
## Running integration tests locally from Windows

The integration tests need to be run from MacOS or Linux.  However, the tests may be run locally within Docker.   

## Docker clean up (Mac/Linux)

! Warning this will remove all images and containers except for the `logstash-base` container !

* `ci/docker_prune.sh`

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


