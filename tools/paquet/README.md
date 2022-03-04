# Paquet

This gem allow a developer to create a uber gem, a uber gem is a gem that content the current gem and his dependencies and is distributed as a tarball.

This tool allow to define what will be bundler and what should be ignored, it uses the dependencies defined in the gemspec and gemfile to know what to download.

Note that by default no gems will be bundled.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'paquet'
```

And then execute:

    $ bundle

## Usage
Define the dependencies in your Rakefile

```ruby
require "paquet"

TARGET_DIRECTORY = File.join(File.dirname(__FILE__), "dependencies")

Paquet::Task.new(TARGET_DIRECTORY) do
  pack "manticore"
  pack "launchy"
  pack "gemoji"
  pack "logstash-output-elasticsearch"

  # Everything not defined here will be assumed to be provided
  # by the target installation
  ignore "logstash-core-plugin-api"
  ignore "logstash-core"
end
```

And run

```
bundle exec rake paquet:vendor
```

The dependencies will be downloaded in your target directory.

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
[CONTRIBUTING](../CONTRIBUTING.md) file.
