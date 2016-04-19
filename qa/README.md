## Acceptance test Framework

Welcome to the acceptance test framework for logstash, in this small
readme we're going to describe it's features and the the necessary steps you will need to
follow to setup your environment.

### Environment setup

This test are based on a collection of Vagrant defined VM's where the
different test are going to be executed, so first setup necessary is to
have vagrant properly available, see https://www.vagrantup.com/ for
details on how to install it.

After you get vagrant installed, you will need to perform the next
setups:

* Cd into the acceptance directory
* run the command `vagrant up`, this will provision all the machines
  defined in the Vagrantfile (located in this directory).

An alternative way would to run the task `rake test:setup` what will do
basically the same.

When this process is done your test can be executed, to do that you will
need to:

_Inside the `qa` directory_

* Execute the command `bundle` this will pull the necessary dependencies in your environment.
* Run `rake test:ssh_config` to dump the ssh configuration to access the different vagrant machines, this will generate a file named `.vm_ssh_config` that is going to be used for the tests.
* Run `bundle exec rake test:acceptance:all` to run all acceptance test
  at once, there is also detailed tasks for platforms:
 * `rake test:acceptance:debian` for debian platforms.
 * `rake test:acceptance:centos` for centos platforms.
