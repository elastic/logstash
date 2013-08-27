---
title: How to extend - logstash
layout: content_right
---
# Extending logstash

You can add your own input, output, or filter plugins to logstash.

If you're looking to extend logstash today, please look at the existing plugins.

## Good examples of plugins

* [inputs/tcp](https://github.com/logstash/logstash/blob/master/lib/logstash/inputs/tcp.rb)
* [filters/multiline](https://github.com/logstash/logstash/blob/master/lib/logstash/filters/multiline.rb)
* [outputs/mongodb](https://github.com/logstash/logstash/blob/master/lib/logstash/outputs/mongodb.rb)

## Common concepts

* The `config_name` sets the name used in the config file.
* The `plugin_status` sets the status of the plugin for example `beta`.
* The `config` lines define config options.
* The `register` method is called per plugin instantiation. Do any of your initialization here.

### Required modules

All plugins should require the Logstash module.

    require 'logstash/namespace'

### Plugin name

Every plugin must have a name set with the `config_name` method. If this
is not specified plugins will fail to load with an error.

### Plugin status

Every plugin needs a status set using `plugin_status`. Valid values are
`stable`, `beta`, `experimental`, and `unsupported`. Plugins with either
the `experimental` and `unsupported` status will generate warnings when
used.
  
### Config lines

The `config` lines define configuration options and are constructed like
so:

    config :host, :validate => :string, :default => "0.0.0.0"

The name of the option is specified, here `:host` and then the
attributes of the option. They can include `:validate`, `:default`,
`:required` (a Boolean `true` or `false`), and `:deprecated` (also a
Boolean).  
 
## Inputs

All inputs require the LogStash::Inputs::Base class:

    require 'logstash/inputs/base'
 
Inputs have two methods: `register` and `run`.

* Each input runs as its own thread.
* The `run` method is expected to run-forever.

## Filters

All filters require the LogStash::Filters::Base class:

    require 'logstash/filters/base'
 
Filters have two methods: `register` and `filter`.

* The `filter` method gets an event. 
* Call `event.cancel` to drop the event.
* To modify an event, simply make changes to the event you are given.
* The return value is ignored.

## Outputs

All outputs require the LogStash::Outputs::Base class:

    require 'logstash/outputs/base'
 
Outputs have two methods: `register` and `receive`.

* The `register` method is called per plugin instantiation. Do any of your initialization here.
* The `receive` method is called when an event gets pushed to your output

## Example: a new filter

Learn by example how to [add a new filter to logstash](example-add-a-new-filter)


