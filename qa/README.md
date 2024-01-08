## Acceptance test Framework

The acceptance test framework for Logstash is intended to test the functionality of packages (`.deb`, `.rpm`)
on various supported platforms.

In this small README we describe its features and the steps necessary for executing it and adding new tests.

### Description

In summary this test framework is composed of:

* A collection of rspec helpers and matchers that make creating tests easy.
* Rspecs helpers that execute commands.

The tests are expected to be executed on the target environment e.g. an Ubuntu 22.04 vm.

### Running tests/Prerequisites

To run the tests from a fresh Logstash checkout, you need to:

1. `./gradlew clean boostrap`
2a. Build the necessary package artifacts e.g. `rake artifact:deb`
  **OR**
2b. Supply a directory where pregenerated package artifacts exit via the `LS_ARTIFACTS_PATH` environment variable (relative and absolute paths are supported).
3. `cd qa`
4. `bundle install`

Now you are ready to kick off the tests:

5. `rake qa:acceptance:all`.

Steps 1, 2b, 3, 4, 5 are executed by the `ci/acceptance_tests.sh` script.

## Architecture of the Framework

### Directory structure

* ```acceptance/```: all the specs definitions.
* ```rspec```: all framework parts necessary to get the test
  running. Includes the commands, the rspec matchers and a
collection of useful helpers.

### I want to add a test, what should I do?

To add a test you basically should start by the acceptance directory,
here you will find an already created tests, most important locations
here are:

* ```lib``` here is where the tests are living. If a test is not going
  to be reused it should be created here.
* ```shared_examples``` inside that directory should be living all tests
  that could be reused in different scenarios, like you can see the CLI
ones.

but we want to write tests, here is an example of how do they look like,
including the different moving parts we encounter in the framework.


```
    logstash = ServiceTester::Artifact.new()

    ## your test code goes here.

    # example:
    it_behaves_like "installable_with_jdk", logstash
    it_behaves_like "updated", logstash, from_release_branch="7.17"
```

Inside the `rspec` directory you will find a
collection of commands, organized per operating system, which
will let you operate and get your tests done.


You'll probably find enough supporting classes for different platforms, but if not, feel free to add more.

An example of an install command on debian looks like:

```
    def installed?(package)
      stdout = ""
      cmd = sudo_exec!("dpkg -s #{package}")
      stdout = cmd.stdout
      stdout.match(/^Package: #{package}$/)
      stdout.match(/^Status: install ok installed$/)
    end
  end
  ```

this is how we run operations and wrap them as ruby code.

### Running a test (detailed level)

There is also the possibility to run your tests with more granularity by
using the `rspec` command, this will let you for example run a single
tests, a collection of them using filtering, etc.

Check https://relishapp.com/rspec/rspec-core/v/3-4/docs/command-line for more details, but here is a quick cheat sheet to run them:

#### Run the examples that get "is installed" in their description

*  bundle exec rspec acceptance/spec -e "is installed" 

#### Run the example defined at line 11

*  bundle exec rspec acceptance/spec/lib/artifact_operation_spec.rb:11
