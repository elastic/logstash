# Logstash [![Code Climate](https://codeclimate.com/github/elasticsearch/logstash/badges/gpa.svg)](https://codeclimate.com/github/elasticsearch/logstash)

### Build status

| Test | master | 5.0 | 2.4 |
|---|---|---|---|
| core | [![Build Status](https://travis-ci.org/elastic/logstash.svg?branch=master)](https://travis-ci.org/elastic/logstash) | [![Build Status](https://travis-ci.org/elastic/logstash.svg?branch=5.0)](https://travis-ci.org/elastic/logstash) | [![Build Status](https://travis-ci.org/elastic/logstash.svg?branch=2.4)](https://travis-ci.org/elastic/logstash) |

Logstash is a tool for managing events and logs. You can use it to collect
logs, parse them, and store them for later use (like, for searching).  If you
store them in [Elasticsearch](https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html),
you can view and analyze them with [Kibana](https://www.elastic.co/guide/en/kibana/current/index.html).

It is fully free and fully open source. The license is Apache 2.0, meaning you
are pretty much free to use it however you want in whatever way.

For more info, see <https://www.elastic.co/products/logstash>

## Logstash Plugins
### AKA "Where'd that plugin go??"

Since version **1.5.0 beta1 (and current master)** of Logstash, *all* plugins have been separated into their own
repositories under the [logstash-plugins](https://github.com/logstash-plugins) github organization. Each plugin is now a self-contained Ruby gem which
gets published to RubyGems.org. Logstash has added plugin infrastructure to easily maintain the lifecyle of the plugin.
For more details and rationale behind these changes, see our [blogpost](https://www.elastic.co/blog/plugin-ecosystem-changes/).

[Elasticsearch logstash-contrib repo](https://github.com/elastic/logstash-contrib) is deprecated. We
have moved all of the plugins that existed there into their own repositories. We are migrating all of the pull requests
and issues from logstash-contrib to the new repositories.

For more info on developing and testing these plugins, please see the [README](https://github.com/logstash-plugins/logstash-output-elasticsearch/blob/master/README.md) on *any* plugin repository.

### Plugin Issues and Pull Requests

**Please open new issues and pull requests for plugins under its own repository**

For example, if you have to report an issue/enhancement for the Elasticsearch output, please do so [here](https://github.com/logstash-plugins/logstash-output-elasticsearch/issues).

Logstash core will continue to exist under this repository and all related issues and pull requests can be submitted here.

## Need Help?

- [#logstash on freenode IRC](https://webchat.freenode.net/?channels=logstash)
- [logstash-users on Google Groups](https://groups.google.com/d/forum/logstash-users)
- [Logstash Documentation](https://www.elastic.co/guide/en/logstash/current/index.html)
- [Logstash Product Information](https://www.elastic.co/products/logstash)
- [Elastic Support](https://www.elastic.co/subscriptions)

## Developing

Logstash uses [JRuby](http://jruby.org/) which gets embedded in the `vendor/jruby/` directory. It is recommended but not mandatory that you also use JRuby as your local Ruby interpreter and for this you should consider using a Ruby version manager such as [RVM](https://rvm.io/) or [rbenv](https://github.com/sstephenson/rbenv). It is possible to run the rake tasks and the `bin/` commands without having JRuby locally installed in which case the embedded JRuby will be used automatically. If you have a local JRuby installed you can force logstash to use your local JRuby instead of the embedded JRuby with the `USE_RUBY=1` environment variable.

To get started, make sure you have a local JRuby or Ruby version 1.9.x or above with the `rake` tool installed.

**On Windows** make sure to set the `JAVA_HOME` environment variable to the path to your JDK installation directory. For example `set JAVA_HOME=<JDK_PATH>`

To run logstash from the repo you must bootstrap the environment

    rake bootstrap

or bootstrap & install the core plugins required to run the tests

    rake test:install-core

To verify your environment, run `bin/logstash version` which should look like this

    $ bin/logstash --version
    logstash 2.0.0.dev

If you are seeing errors that look like

    $ rake bootstrap
    Installing minitar >= 0 because the build process needs it.
    [bootstrap] Fetching and installing gem: minitar (>= 0)
    rake aborted!
    LoadError: no such file to load -- archive/tar/minitar
    /Users/<user>/projects/logstash/rakelib/vendor.rake:17:in `untar'
    /Users/<user>/projects/logstash/rakelib/vendor.rake:86:in `(root)'
    Tasks: TOP => bootstrap => vendor:all => vendor:jruby
    (See full trace by running task with --trace)

then you may need to update your version of rubygems. Run `gem -v` to see the version of rubygems installed. Version 2.5.2 or higher should work. To update rubygems run `gem update --system` (you may need to run with `sudo` if you're using your system Ruby environment).

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

## Developing plugins

The documentation for developing plugins can be found in the plugins README, see our example plugins:

- <https://github.com/logstash-plugins/logstash-input-example>
- <https://github.com/logstash-plugins/logstash-filter-example>
- <https://github.com/logstash-plugins/logstash-output-example>
- <https://github.com/logstash-plugins/logstash-codec-example>

## Drip Launcher

[Drip](https://github.com/ninjudd/drip) is a tool that solves the slow JVM startup problem. The drip script is intended to be a drop-in replacement for the java command. We recommend using drip during development, in particular for running tests. Using drip, the first invocation of a command will not be faster but the subsequent commands will be swift.

To tell logstash to use drip, either set the `USE_DRIP=1` environment variable or set `` JAVACMD=`which drip` ``.

Examples:

    USE_DRIP=1 bin/rspec
    USE_DRIP=1 bin/rspec

**Caveats**

Drip does not work with STDIN. You cannot use drip for running configs which use the stdin plugin.


## Building

You can build a logstash package as tarball or zip file

    rake artifact:tar
    rake artifact:zip

You can also build .rpm and .deb, but the [fpm](https://github.com/jordansissel/fpm) tool is required.

    rake artifact:rpm
    rake artifact:deb

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
