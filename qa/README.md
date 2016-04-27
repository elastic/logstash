## Acceptance test Framework

Welcome to the acceptance test framework for logstash, in this small
readme we're going to describe it's features and the the necessary steps you will need to
follow to setup your environment.

### Environment setup and Running Tests

It is possible to run the full suite of the acceptance test with the codebase by 
running the command `ci/ci_acceptance.sh`, this command will generate the artefacts, bootstrap
the VM and run the tests.


This test are based on a collection of Vagrant defined VM's where the
different test are going to be executed, so first setup necessary is to
have vagrant properly available, see https://www.vagrantup.com/ for
details on how to install it.

_Inside the `qa` directory_

* Execute the command `bundle` this will pull the necessary dependencies in your environment.
* start your machines with `bundle exec test:setup`
* Run `rake test:ssh_config` to dump the ssh configuration to access the different vagrant machines, this will generate a file named `.vm_ssh_config` that is going to be used for the tests.
* Run `bundle exec rake test:acceptance:all` to run all acceptance test
  at once, there is also detailed tasks for platforms:
 * `rake test:acceptance:debian` for debian platforms.
 * `rake test:acceptance:centos` for centos platforms.
