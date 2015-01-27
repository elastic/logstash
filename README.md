# Logstash [![Code Climate](https://codeclimate.com/github/elasticsearch/logstash/badges/gpa.svg)](https://codeclimate.com/github/elasticsearch/logstash) [![Coverage Status](https://coveralls.io/repos/elasticsearch/logstash/badge.svg?branch=origin%2Fmaster)](https://coveralls.io/r/elasticsearch/logstash?branch=origin%2Fmaster)

Logstash is a tool for managing events and logs. You can use it to collect
logs, parse them, and store them for later use (like, for searching). Speaking
of searching, Logstash comes with a web interface for searching and drilling
into all of your logs.

It is fully free and fully open source. The license is Apache 2.0, meaning you
are pretty much free to use it however you want in whatever way.

For more info, see <http://logstash.net/>

## Logstash Plugins
### AKA "Where'd that plugin go??"

Since version **1.5.0 beta1 (and current master)** of Logstash, *all* plugins have been separated into their own
repositories under the [logstash-plugins](https://github.com/logstash-plugins) github organization. Each plugin is now a self-contained Ruby gem which
gets published to RubyGems.org. Logstash has added plugin infrastructure to easily maintain the lifecyle of the plugin.
For more details and rationale behind these changes, see our [blogpost](http://www.elasticsearch.org/blog/plugin-ecosystem-changes/). 

[Elasticsearch logstash-contrib repo](https://github.com/elasticsearch/logstash-contrib) is deprecated. We
have moved all of the plugins that existed there into their own repositories. We are migrating all of the pull requests
and issues from logstash-contrib to the new repositories.

For more info on developing and testing these plugins, please see the [README](https://github.com/logstash-plugins/logstash-output-elasticsearch/blob/master/README.md) on *any* plugin repository.

### Plugin Issues and Pull Requests

We are migrating all of the existing pull requests to their respective repositories. Rest assured, we will maintain
all of the git history for these requests. 

**Please open new issues and pull requests for plugins under its own repository**

For example, if you have to report an issue/enhancement for the Elasticsearch output, please do so [here](https://github.com/logstash-plugins/logstash-output-elasticsearch/issues).

Logstash core will continue to exist under this repository and all related issues and pull requests can be submitted here.

## Need Help?

Need help? Try #logstash on freenode irc or the logstash-users@googlegroups.com
mailing list.

You can also find documentation on the <http://logstash.net> site.

## Developing

To get started, you'll need *any* ruby available and it should come with the `rake` tool.

Here's how to get started with Logstash development:

    rake bootstrap
    
Other commands:

    # to use Logstash gems or libraries in irb, use the following
    # this gets you an 'irb' shell with Logstash's environment
    bin/logstash irb

    # Run Logstash
    bin/logstash agent [options]

Notes about using other rubies. If you don't use rvm, you can probably skip
this paragraph. Logstash works with other rubies, and if you wish to use your
own ruby you must set `USE_RUBY=1` in your environment.

We recommend using flatland/drip for faster startup times during development. To
tell Logstash to use drip, set `USE_DRIP=1` in your environment.

## Testing

There are a few ways to run the tests. For development, using `bin/logstash
rspec <some spec>` will suffice:

    % bin/logstash rspec spec/core/timestamp_spec.rb
    Using Accessor#strict_set for spec
    .............
    13 examples, 0 failures
    Randomized with seed 8026

If you want to run all the tests from source, do:

    rake test

## Building

Building is not required. You are highly recommended to download the releases
we provide from the Logstash site!

If you want to build the release tarball yourself, run:

    rake artifact:tar

You can build rpms and debs, if you need those. Building rpms requires you have [fpm](https://github.com/jordansissel/fpm), then do this:

    # Build an RPM
    rake artifact:rpm

    # Build a Debian/Ubuntu package
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
[CONTRIBUTING](CONTRIBUTING.md) file.
