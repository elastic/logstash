---
title: How to extend - logstash
layout: content_right
---
# Add a new filter

This document shows you how to add a new filter to logstash.

For a general overview of how to add a new plugin, see [the extending
logstash](.) overview.

## Write code.

Let's write a 'hello world' filter. This filter will replace the 'message' in
the event with "Hello world!"

First, logstash expects plugins in a certain directory structure: `logstash/TYPE/PLUGIN_NAME.rb`

Since we're creating a filter, let's mkdir this:

    mkdir -p logstash/filters/
    cd logstash/filters

Now add the code:

    # Call this file 'foo.rb' (in logstash/filters, as above)
    require "logstash/filters/base"
    require "logstash/namespace"

    class LogStash::Filters::Foo < LogStash::Filters::Base

      # Setting the config_name here is required. This is how you
      # configure this filter from your logstash config.
      #
      # filter {
      #   foo { ... }
      # }
      config_name "foo"

      # New plugins should start life at milestone 1.
      milestone 1

      # Replace the message with this value.
      config :message, :validate => :string

      public
      def register
        # nothing to do
      end # def register

      public
      def filter(event)
        # return nothing unless there's an actual filter event
        return unless filter?(event)
        if @message
          # Replace the event message with our message as configured in the
          # config file.
          event["message"] = @message
        end
        # filter_matched should go in the last line of our successful code 
        filter_matched(event)
      end # def filter
    end # class LogStash::Filters::Foo

## Add it to your configuration

For this simple example, let's just use stdin input and stdout output.
The config file looks like this:

    input { 
      stdin { type => "foo" } 
    }
    filter {
      if [type] == "foo" {
        foo {
          message => "Hello world!"
        }
      }
    }
    output {
      stdout { }
    }

Call this file 'example.conf'

## Tell logstash about it.

Depending on how you installed logstash, you have a few ways of including this
plugin.

You can use the agent flag --pluginpath flag to specify where the root of your
plugin tree is. In our case, it's the current directory.

    % bin/logstash --pluginpath your/plugin/root -f example.conf

## Example running

In the example below, I typed in "the quick brown fox" after running the java
command.

    % bin/logstash -f example.conf
    the quick brown fox   
    2011-05-12T01:05:09.495000Z stdin://snack.home/: Hello world!

The output is the standard logstash stdout output, but in this case our "the
quick brown fox" message was replaced with "Hello world!"

All done! :)
