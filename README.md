# Logstash

Logstash is part of the [Elastic Stack](https://www.elastic.co/products) along with Beats, Elasticsearch and Kibana. Logstash is a server-side data processing pipeline that ingests data from a multitude of sources simultaneously, transforms it, and then sends it to your favorite "stash." (Ours is Elasticsearch, naturally.). Logstash has over 200 plugins, and you can write your own very easily as well.

For more info, see <https://www.elastic.co/products/logstash>

## Documentation and Getting Started

You can find the documentation and getting started guides for Logstash
on the [elastic.co site](https://www.elastic.co/guide/en/logstash/current/getting-started-with-logstash.html)

For information about building the documentation, see the README in https://github.com/elastic/docs

## Downloads

You can download officially released Logstash binaries, as well as debian/rpm packages for the
supported platforms, from [downloads page](https://www.elastic.co/downloads/logstash).

## Need Help?

- [Logstash Forum](https://discuss.elastic.co/c/logstash)
- [Logstash Documentation](https://www.elastic.co/guide/en/logstash/current/index.html)
- [#logstash on freenode IRC](https://webchat.freenode.net/?channels=logstash)
- [Logstash Product Information](https://www.elastic.co/products/logstash)
- [Elastic Support](https://www.elastic.co/subscriptions)

## Logstash Plugins

Logstash plugins are hosted in separate repositories under the [logstash-plugins](https://github.com/logstash-plugins) github organization. Each plugin is a self-contained Ruby gem which gets published to RubyGems.org.

### Writing your own Plugin

Logstash is known for its extensibility. There are hundreds of plugins for Logstash and you can write your own very easily! For more info on developing and testing these plugins, please see the [working with plugins section](https://www.elastic.co/guide/en/logstash/current/contributing-to-logstash.html)

### Plugin Issues and Pull Requests

**Please open new issues and pull requests for plugins under its own repository**

For example, if you have to report an issue/enhancement for the Elasticsearch output, please do so [here](https://github.com/logstash-plugins/logstash-output-elasticsearch/issues).

Logstash core will continue to exist under this repository and all related issues and pull requests can be submitted here.

## Developing Logstash Core

### Prerequisites

* Install JDK version 11 or 17. Make sure to set the `JAVA_HOME` environment variable to the path to your JDK installation directory. For example `set JAVA_HOME=<JDK_PATH>`
* Install JRuby 9.2.x It is recommended to use a Ruby version manager such as [RVM](https://rvm.io/) or [rbenv](https://github.com/sstephenson/rbenv).
* Install `rake` and `bundler` tool using `gem install rake` and `gem install bundler` respectively.

### RVM install (optional)

If you prefer to use rvm (ruby version manager) to manage Ruby versions on your machine, follow these directions. In the Logstash folder:

```sh
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
\curl -sSL https://get.rvm.io | bash -s stable --ruby=$(cat .ruby-version)
```

### Check Ruby version

Before you proceed, please check your ruby version by:

```sh
$ ruby -v
```

The printed version should be the same as in the `.ruby-version` file.

### Building Logstash

The Logstash project includes the source code for all of Logstash, including the Elastic-Licensed X-Pack features and functions; to run Logstash from source using only the OSS-licensed code, export the `OSS` environment variable with a value of `true`:

``` sh
export OSS=true
```

* Set up the location of the source code to build

``` sh
export LOGSTASH_SOURCE=1
export LOGSTASH_PATH=/YOUR/LOGSTASH/DIRECTORY
```

#### Install dependencies with `gradle` **(recommended)**[^1]

* Install development dependencies
```sh
./gradlew installDevelopmentGems
```

* Install default plugins and other dependencies

```sh
./gradlew installDefaultGems
```

### Verify the installation

To verify your environment, run the following to start Logstash and send your first event:

```sh
bin/logstash -e 'input { stdin { } } output { stdout {} }'
```

This should start Logstash with stdin input waiting for you to enter an event

```sh
hello world
2016-11-11T01:22:14.405+0000 0.0.0.0 hello world
```

**Advanced: Drip Launcher**

[Drip](https://github.com/ninjudd/drip) is a tool that solves the slow JVM startup problem while developing Logstash. The drip script is intended to be a drop-in replacement for the java command. We recommend using drip during development, in particular for running tests. Using drip, the first invocation of a command will not be faster but the subsequent commands will be swift.

To tell logstash to use drip, set the environment variable `` JAVACMD=`which drip` ``.

Example (but see the *Testing* section below before running rspec for the first time):

    JAVACMD=`which drip` bin/rspec

**Caveats**

Drip does not work with STDIN. You cannot use drip for running configs which use the stdin plugin.

## Building Logstash Documentation

To build the Logstash Reference (open source content only) on your local
machine, clone the following repos:

[logstash](https://github.com/elastic/logstash) - contains main docs about core features

[logstash-docs](https://github.com/elastic/logstash-docs) - contains generated plugin docs

[docs](https://github.com/elastic/docs) - contains doc build files

Make sure you have the same branch checked out in `logstash` and `logstash-docs`.
Check out `master` in the `docs` repo.

Run the doc build script from within the `docs` repo. For example:

```
./build_docs.pl --doc ../logstash/docs/index.asciidoc --chunk=1 -open
```

## Testing

Most of the unit tests in Logstash are written using [rspec](http://rspec.info/) for the Ruby parts. For the Java parts, we use [junit](https://junit.org). For testing you can use the *test* `rake` tasks and the `bin/rspec` command, see instructions below:

### Core tests

1- To run the core tests you can use the Gradle task:

    ./gradlew test

  or use the `rspec` tool to run all tests or run a specific test:

    bin/rspec
    bin/rspec spec/foo/bar_spec.rb

  Note that before running the `rspec` command for the first time you need to set up the RSpec test dependencies by running:

    ./gradlew bootstrap

2- To run the subset of tests covering the Java codebase only run:

    ./gradlew javaTests

3- To execute the complete test-suite including the integration tests run:

    ./gradlew check

4- To execute a single Ruby test run:

    SPEC_OPTS="-fd -P logstash-core/spec/logstash/api/commands/default_metadata_spec.rb" ./gradlew :logstash-core:rubyTests --tests org.logstash.RSpecTests

5- To execute single spec for integration test, run:

    ./gradlew integrationTests -PrubyIntegrationSpecs=specs/slowlog_spec.rb

Sometimes you might find a change to a piece of Logstash code causes a test to hang. These can be hard to debug.

If you set `LS_JAVA_OPTS="-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5005"` you can connect to a running Logstash with your IDEs debugger which can be a great way of finding the issue.

### Plugins tests

To run the tests of all currently installed plugins:

    rake test:plugins

You can install the default set of plugins included in the logstash package:

    rake test:install-default

---
Note that if a plugin is installed using the plugin manager `bin/logstash-plugin install ...` do not forget to also install the plugins development dependencies using the following command after the plugin installation:

    bin/logstash-plugin install --development

## Building Artifacts

Built artifacts will be placed in the `LS_HOME/build` directory, and will create the directory if it is not already present.

You can build a Logstash snapshot package as tarball or zip file

```sh
./gradlew assembleTarDistribution
./gradlew assembleZipDistribution
```

OSS-only artifacts can similarly be built with their own gradle tasks:
```sh
./gradlew assembleOssTarDistribution
./gradlew assembleOssZipDistribution

```

You can also build .rpm and .deb, but the [fpm](https://github.com/jordansissel/fpm) tool is required.

```sh
rake artifact:rpm
rake artifact:deb
```

and:

```sh
rake artifact:rpm_oss
rake artifact:deb_oss
```

## Using a Custom JRuby Distribution

If you want the build to use a custom JRuby you can do so by setting a path to a custom
JRuby distribution's source root via the `custom.jruby.path` Gradle property.

E.g.

```sh
./gradlew clean test -Pcustom.jruby.path="/path/to/jruby"
```

## Project Principles

* Community: If a newbie has a bad time, it's a bug.
* Software: Make it work, then make it right, then make it fast.
* Technology: If it doesn't do a thing today, we can make it do it tomorrow.

## Contributing

All contributions are welcome: ideas, patches, documentation, bug reports,
complaints, and even something you drew up on a napkin.

Programming is not a required skill. Whatever you've seen about open source and
maintainers or community members saying "send patches or die" - you will not
see that here.

It is more important that you are able to contribute.

For more information about contributing, see the
[CONTRIBUTING](./CONTRIBUTING.md) file.

## Footnotes

[^1]: <details><summary>Use bundle instead of gradle to install dependencies</summary>

    #### Alternatively, instead of using `gradle` you can also use `bundle`:

    * Install development dependencies

        ```sh
        bundle config set --local path vendor/bundle
        bundle install
        ```

    * Bootstrap the environment:

        ```sh
        rake bootstrap
        ```

    * You can then use `bin/logstash` to start Logstash, but there are no plugins installed. To install default plugins, you can run:

        ```sh
        rake plugin:install-default
        ```

    This will install the 80+ default plugins which makes Logstash ready to connect to multiple data sources, perform transformations and send the results to Elasticsearch and other destinations.
    </details>
