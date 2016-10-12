## Acceptance test Framework

Welcome to the acceptance test framework for logstash, in this small
README we're going to describe it's features and the necessary steps you will need to
follow to setup your environment.

### Setup your environment

In summary this test framework is composed of:

* A collection of rspec helpers and matchers that make creating tests
  easy.
* This rspecs helpers execute commands over SSH to a set of machines.
* The tests are run, for now, as vagrant (virtualbox provided) machines.

As of this, you need to have installed:

* The latest version vagrant (=> 1.8.1)
* Virtualbox as VM provider (=> 5.0)

Is important to notice that the first time you set everything up, or when a
new VM is added, there is the need to download the box (this will
take a while depending on your internet speed).

### Running Tests

It is possible to run the full suite of the acceptance test with the codebase by 
running the command `ci/ci_acceptance.sh`, this command will generate the artifacts, bootstrap
the VM and run the tests.

This test are based on a collection of Vagrant defined VM's where the
different test are going to be executed, so first setup necessary is to
have vagrant properly available, see https://www.vagrantup.com/ for
details on how to install it.

_Inside the `qa` directory_

First of all execute the command `bundle` this will pull the necessary
dependencies in your environment, after this is done, this is the collection of task available for you:

```
skywalker% rake -T
rake qa:acceptance:all              # Run all acceptance
rake qa:acceptance:debian           # Run acceptance test in debian machines
rake qa:acceptance:redhat           # Run acceptance test in redhat machines
rake qa:acceptance:single[machine]  # Run one single machine acceptance test
rake qa:acceptance:suse             # Run acceptance test in suse machines
rake qa:vm:halt[platform]           # Halt all VM's involved in the acceptance test round
rake qa:vm:setup[platform]          # Bootstrap all the VM's used for this tests
rake qa:vm:ssh_config               # Generate a valid ssh-config
```

Important to be aware that using any of this commands:

```
rake qa:acceptance:all              # Run all acceptance
rake qa:acceptance:debian           # Run acceptance test in debian machines
rake qa:acceptance:redhat           # Run acceptance test in redhat machines
rake qa:acceptance:suse             # Run acceptance test in suse machines
```

before you *will have to bootstrap* all selected machines, you can do
that using the `rake qa:vm:setup[platform]` task. This is done like this
as bootstrap imply setting up the VM'S and this might take some time and
you might only want to this once.

In the feature we might add new rake tasks to do all at once, but for now you can use the script under
`ci/ci_acceptance.sh` to do all at once.

For local testing purposes, is recommended to not run all together, pick your target and run with the single machine command, If you're willing to run on single one, you should use:

```
rake qa:acceptance:single[machine]  # Run one single machine acceptance test
```

### How to run tests

If you are *running this test for first time*, you will need to setup
your VM's first, you can do that using either `vagrant up` or `rake qa:vm:setup[platform]`. 

In this framework we're using ssh to connect to a collection of Vagrant
machines, so first and most important is to generate a valid ssh config
file, this could be done running `rake qa:vm:ssh_config`. When this task
is finished a file named `.vm_ssh_config` will be generated with all the
necessary information to connect with the different machines.

Now is time to run your test and to do that we have different options:

* rake qa:acceptance:all              # Run all acceptance
* rake qa:acceptance:debian           # Run acceptance test in debian machines
* rake qa:acceptance:redhat           # Run acceptance test in redhat machines
* rake qa:acceptance:suse             # Run acceptance test in suse machines
* rake qa:acceptance:single[machine]  # Run one single machine acceptance test

Generally speaking this are complex tests so they take a long time to
finish completely, if you look for faster feedback see at the end of this
README how to run fewer tests.

## Architecture of the Framework

If you wanna know more about how this framework works, here is your
section of information.

### Directory structure

* ```acceptance/``` here it goes all the specs definitions.
* ```config```  inside you can find all config files, for now only the
  platform definition.
* ```rspec``` here stay all framework parts necessary to get the test
  running, you will find the commands, the rspec matchers and a
collection of useful helpers for your test.
* ```sys``` a collection of bash scripts used to bootstrap the machines.
* ```vagrant``` classes and modules used to help us running vagrant.

### The platform configuration file

Located inside the config directory there is the platforms.json which is used to define the different platforms we test with.
Important bits here are:

* `latest` key defines the latest published version of LS release which is used to test the package upgrade scenario.
* inside the `platforms` key you will find the list of current available
  OS we tests with, this include the box name, their type and if they
have to go under specific bootstrap scripts (see ```specific: true ```
in the platform definition).

This file is the one that you will use to know about differnt OS's
testes, add new ones, etc..

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
  config = ServiceTester.configuration
  config.servers.each do |address|
    ##
    # ServiceTester::Artifact is the component used to interact with the
    # destination machineri and the one that keep the necessary logic
    # for it.
    ##

    logstash = ServiceTester::Artifact.new(address, config.lookup[address])

    ## your test code goes here.
  end
```

this is important because as you know we test with different machines,
so the build out artifact will be the component necessary to run the
actions with the destination machine.

but this is the main parts, to run your test you need the framework
located inside the ```rspec``` directory. Here you will find a
collection of commands, properly organized per operating system, that
will let you operate and get your tests done. But don't freak out, we
got all logic necessary to select the right one for your test.

You'll probably find enough supporting classes for different platforms, but if not, feel free to add it.

FYI, this is how a command looks like:

```
    def installed?(hosts, package)
      stdout = ""
      at(hosts, {in: :serial}) do |host|
        cmd = sudo_exec!("dpkg -s  #{package}")
        stdout = cmd.stdout
      end
      stdout.match(/^Package: #{package}$/)
      stdout.match(/^Status: install ok installed$/)
  end
  ```
this is how we run operations and wrap them as ruby code.

### Running a test (detailed level)

There is also the possibility to run your tests with more granularity by
using the `rspec` command, this will let you for example run a single
tests, a collection of them using filtering, etc.

Check https://relishapp.com/rspec/rspec-core/v/3-4/docs/command-line for more details, but here is a quick cheat sheet to run them:

# Run the examples that get "is installed" in their description

*  bundle exec rspec acceptance/spec -e "is installed" 

# Run the example defined at line 11

*  bundle exec rspec acceptance/spec/lib/artifact_operation_spec.rb:11
