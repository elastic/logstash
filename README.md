# Logstash

### Build status

| Test | master | 5.0 | 2.4 |
|---|---|---|---|
| core | [![Build Status](https://travis-ci.org/elastic/logstash.svg?branch=master)](https://travis-ci.org/elastic/logstash) | [![Build Status](https://travis-ci.org/elastic/logstash.svg?branch=5.0)](https://travis-ci.org/elastic/logstash) | [![Build Status](https://travis-ci.org/elastic/logstash.svg?branch=2.4)](https://travis-ci.org/elastic/logstash) |

Logstash is part of the [Elastic Stack](https://www.elastic.co/products) along with Beats, Elasticsearch and Kibana. Logstash is an open source, server-side data processing pipeline that ingests data from a multitude of sources simultaneously, transforms it, and then sends it to your favorite "stash." (Ours is Elasticsearch, naturally.). Logstash has over 200 plugins, and you can write your own very easily as well.

The license is Apache 2.0, meaning you are pretty much free to use it however you want in whatever way.

For more info, see <https://www.elastic.co/products/logstash>

## Documentation and Getting Started

You can find the documentation and getting started guides for Logstash 
on the [elastic.co site](https://www.elastic.co/guide/en/logstash/current/getting-started-with-logstash.html)

## Downloads

You can download Logstash binaries, as well as debian/rpm packages for the
supported platforms, from [downloads page](https://www.elastic.co/downloads/logstash).

## Need Help?

- [Logstash Forum](https://discuss.elastic.co/c/logstash)
- [Logstash Documentation](https://www.elastic.co/guide/en/logstash/current/index.html)
- [#logstash on freenode IRC](https://webchat.freenode.net/?channels=logstash)
- [Logstash Product Information](https://www.elastic.co/products/logstash)
- [Elastic Support](https://www.elastic.co/subscriptions)

## Logstash Plugins

Logstash plugins are hosted in separate repositories under under the [logstash-plugins](https://github.com/logstash-plugins) github organization. Each plugin is a self-contained Ruby gem which gets published to RubyGems.org.

### Writing your own Plugin

Logstash is known for its extensibility. There are hundreds of plugins for Logstash and you can write your own very easily! For more info on developing and testing these plugins, please see the [working with plugins section](https://www.elastic.co/guide/en/logstash/current/contributing-to-logstash.html)

### Plugin Issues and Pull Requests

**Please open new issues and pull requests for plugins under its own repository**

For example, if you have to report an issue/enhancement for the Elasticsearch output, please do so [here](https://github.com/logstash-plugins/logstash-output-elasticsearch/issues).

Logstash core will continue to exist under this repository and all related issues and pull requests can be submitted here.

## Developing Logstash Core

### Prerequisites

* Install JDK version 8
* Install JRuby 1.7.x.
* Install `rake` and `bundler` tool using `gem install rake` and `gem install bundler` respectively.

**On Windows** make sure to set the `JAVA_HOME` environment variable to the path to your JDK installation directory. For example `set JAVA_HOME=<JDK_PATH>`

**Vendored JRuby**: Logstash uses [JRuby](http://jruby.org/) which gets embedded in the `vendor/jruby/` directory. It is recommended to use a Ruby version manager such as [RVM](https://rvm.io/) or [rbenv](https://github.com/sstephenson/rbenv).

* To run Logstash from the repo you must first bootstrap the environment:

```sh
rake bootstrap
```
    
* You can then use `bin/logstash` to start Logstash, but there are no plugins installed. Logstash ships with default plugins. To install those, you can run:

```sh
rake plugin:install-default
```

* Alternatively, you can only install the core plugins required to run the tests

```sh
rake test:install-core
```

To verify your environment, run

```sh
bin/logstash -e 'input { stdin { } } output { stdout {} }'
```

This should start Logstash with stdin input waiting for you to enter an event

```sh
hello world
2016-11-11T01:22:14.405+0000 0.0.0.0 hello world
```

**Drip Launcher**

[Drip](https://github.com/ninjudd/drip) is a tool that solves the slow JVM startup problem while developing Logstash. The drip script is intended to be a drop-in replacement for the java command. We recommend using drip during development, in particular for running tests. Using drip, the first invocation of a command will not be faster but the subsequent commands will be swift.

To tell logstash to use drip, either set the `USE_DRIP=1` environment variable or set `` JAVACMD=`which drip` ``.

Example:

    USE_DRIP=1 bin/rspec

**Caveats**

Drip does not work with STDIN. You cannot use drip for running configs which use the stdin plugin.

## Testing

For testing you can use the *test* `rake` tasks and the `bin/rspec` command, see instructions below. Note that the `bin/logstash rspec` command has been replaced by `bin/rspec`.

### Core tests

1- In order to run the core tests, a small set of plugins must first be installed:

    rake test:install-core

2- To run the logstash core tests you can use the rake task:

    rake test:core

  or use the `rspec` tool to run all tests or run a specific test:

    bin/rspec
    bin/rspec spec/foo/bar_spec.rb

### Plugins tests

To run the tests of all currently installed plugins:

    rake test:plugin

You can install the default set of plugins included in the logstash package or all plugins:

    rake test:install-default
    rake test:install-all

---
Note that if a plugin is installed using the plugin manager `bin/logstash-plugin install ...` do not forget to also install the plugins development dependencies using the following command after the plugin installation:

    bin/logstash-plugin install --development
    
## Building Artifacts

You can build a Logstash snapshot package as tarball or zip file

```sh
rake artifact:tar
rake artifact:zip
```

This will create the artifact `LS_HOME/build` directory

You can also build .rpm and .deb, but the [fpm](https://github.com/jordansissel/fpm) tool is required.

```sh
rake artifact:rpm
rake artifact:deb
```

## Project Principles

* Community: If a newbie has a bad time, it's a bug.
* Software: Make it work, then make it right, then make it fast.
* Technology: If it doesn't do a thing today, we can make it do it tomorrow.

## Contributing

All contributions are welcome: ideas, patches, documentation, bug reports,
complaints, and even something you drew up on a napkin.

Programming is not a required skill. Whatever you've seen about open source and
maintainers or community members  saying "send patches or die" - you will not
see that here.

It is more important to me that you are able to contribute.

For more information about contributing, see the
[CONTRIBUTING](./CONTRIBUTING.md) file.
