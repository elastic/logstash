# logstash

[![Build Status](https://secure.travis-ci.org/logstash/logstash.png)](http://travis-ci.org/logstash/logstash)

logstash is a tool for managing events and logs. You can use it to collect
logs, parse them, and store them for later use (like, for searching). Speaking
of searching, logstash comes with a web interface for searching and drilling
into all of your logs.

It is fully free and fully open source. The license is Apache 2.0, meaning you
are pretty much free to use it however you want in whatever way.

For more info, see <http://logstash.net/>

## Need Help?

Need help? Try #logstash on freenode irc or the logstash-users@googlegroups.com
mailing list.

You can also find documentation on the <http://logstash.net> site.

## Developing

If you don't have JRuby already (or don't use rvm, rbenv, etc), you can have `bin/logstash` fetch it for you by setting `USE_JRUBY`:

    USE_JRUBY=1 bin/logstash ...

Otherwise, here's how to get started with rvm: 

    # Install JRuby with rvm
    rvm install jruby-1.7.8
    rvm use jruby-1.7.8

Now install dependencies:

    # Install logstash ruby dependencies
    bin/logstash deps

Other commands:

    # to use logstash gems or libraries in irb, use the following
    # this gets you an 'irb' shell with logstash's environment
    bin/logstash irb

    # or use irb from the jar
    java -jar logstash-<version>-monolithic.jar irb

    # Run logstash
    bin/logstash agent [options]
    
    # If running bin/logstash agent yields complaints about log4j/other things
    # This will download the elasticsearch jars so logstash can use them.
    make vendor-elasticsearch

## Testing

There are a few ways to run the tests. For development, using `bin/logstash
rspec <some spec>` will suffice:

    % bin/logstash rspec spec/filters/grok.rb 
    ...................

    Finished in 0.123 seconds
    19 examples, 0 failures

Alternately, if you have just built the flatjar, you can run the tests
specifically on those like so:

    make flatjar-test

If you want to run all the tests from source (not compiled jar), do:

    make test

Finally, like 'bin/logstash rspec' above, you can invoke the jar to run a
specific test like so:

    % java -jar logstash.jar rspec spec/filters/grok.rb
    ...................

    Finished in 0.346 seconds
    19 examples, 0 failures

## Building

Building is not required. You are highly recommended to download the releases
we provide from the logstash site!

If you want to build the jar yourself, run:

    make flatjar

To update a flat jar previously built with 'make flatjar', run:

    make update-flatjar


You can build rpms and debs, if you need those. Building rpms requires you have [fpm](github.com/jordansissel/fpm), then do this:

    make package

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
