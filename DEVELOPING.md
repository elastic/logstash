# Logstash Development Workflow

This explains how to develop in the logstash core code-base. We will use to following fictional directories:

- `/logstash/` is the dir containing your local fork clone of logstash
- `/plugins/...` is the dir containing your local fork clones of logstash plugins or any other local private plugins

## Setup

Logstash uses [JRuby](http://jruby.org/) which gets embedded in the `vendor/jruby/` directory. It is **highly recommended** but not mandatory that you also use JRuby as your local Ruby interpreter and for this you should consider using a Ruby version manager such as [RVM](https://rvm.io/) or [rbenv](https://github.com/sstephenson/rbenv). It is possible to run the rake tasks and the `bin/` commands without having JRuby locally installed in which case the embedded JRuby will be used automatically.

You will also need to have a JVM installed, we recommend using Java 1.8.

`Rake` and `Bundler` should also be installed in your environment.

Note that if you have a local JRuby installed you can force logstash to use your local JRuby instead of the embedded JRuby with the `USE_RUBY=1` environment variable.


## Bootstrapping

The logstash environment need to be bootstrapped to install base dependencies in the `vendor/` directory. Use the following command to bootstrap:

```sh
$ rake bootstrap
```

After bootstrap, logstash can be launched using `bin/logstash` but note that at this point, no plugin is installed.

### Installing Core Plugins

The logstash core plugins are required to run the core tests/specs. These core plugins and their development dependencies can be installed using:

```sh
$ rake test:install-core
```

### Installing Default Plugins

Logstash is packaged with a default set of plugins. To install the set of default plugins and their development dependencies use:

```sh
$ rake test:install-default
```

### Installing All Plugins

```sh
$ rake test:install-all
```

## Testing

Testing in logstash basically consist on 2 sets of tests, the core tests and the plugin tests

### Core Tests

The Logstash core tests are against core logstash code. Running all core tests can be done using:

```sh
rake test:core
```

Or individual test suites can be run using:

```sh
bin/rspec spec
bin/rspec logstash-core/spec
bin/rspec logstash-core-event/spec
```

Note that it is important to use `bin/rspec` and not just `rspec` because `bin/rspec` is aware of our specific environment. Both commands uses the same arguments.

### Plugin tests

It is possible to run all the **installed** plugins tests/specs from within the logstash development env which has the benefit of making sure all installed plugins tests/specs are passing againt the current development code-base. To run the tests/specs of all installed plugins use:

```sh
rake test:plugins
```

Normally you will want to make sure that the default set of plugins are passing the tests/specs. You read above on how install the plugins in your development envirinment.


### Installing Development Dependencies

If for any reason, for example a plugins was installed directly with `bin/plugin install ...`, it is possible to install the missing development dependencies which are required to run the tests/specs using:

```sh
rake plugin:install-development-dependencies
```

or

```sh
bin/plugin install --development
```

both are equivalent.

## Using Alternate Core Modules

Logstash depends on two core modules:

- logstash-core

  contains the pipeline related code.

- logstash-core-event

  contains the event related code.

Both are self contained gems and both live in the logstash main repository in `logstash-core/` and `logstash-core-event/`. By default logstash will use both core module in the development directories. It is possible to use alternate implementations of these modules.

TBD

## Using Drip

TBD

## Building Packages

TBD

## Developping Plugins

TDB