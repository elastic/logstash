# Logstash [![Code Climate](https://codeclimate.com/github/elasticsearch/logstash/badges/gpa.svg)](https://codeclimate.com/github/elasticsearch/logstash)

Logstash is a tool for managing events and logs. You can use it to collect
logs, parse them, and store them for later use (like, for searching). Speaking
of searching, Logstash comes with a web interface for searching and drilling
into all of your logs.

It is fully free and fully open source. The license is Apache 2.0, meaning you
are pretty much free to use it however you want in whatever way.

For more info, see <http://logstash.net/>

## logstash-contrib
### AKA "Where'd that plugin go??"

Since version 1.4.0 of Logstash, some of the community-contributed plugins were
moved to a new home in the
[Elasticsearch logstash-contrib repo](https://github.com/elasticsearch/logstash-contrib).
If you can't find a plugin here which you've previously used, odds are it is now
located there. The good news is that these plugins are simple to install using the
[Logstash manual plugin installation script](http://logstash.net/docs/latest/contrib-plugins).

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

    % bin/logstash rspec spec/filters/grok.rb
    ...................

    Finished in 0.123 seconds
    19 examples, 0 failures

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
