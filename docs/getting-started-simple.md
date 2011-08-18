---
title: Getting Started (Standalone server) - logstash
layout: content_right
---
# Getting started with logstash (standalone server example)

This guide shows how to get you going quickly with logstash on a single,
standalone server collecting its own logs. By standalone, I mean that
everything happens on a single server: log collection, indexing, and the web
interface.

logstash can be run on multiple servers (collect from many servers to a single
indexer) if you want, but this example shows simply a standalone configuration.

Steps detailed in this guide:

* Download and run logstash

## Problems?

If you have problems, feel free to email the users list
(logstash-users@googlegroups.com) or join IRC (#logstash on irc.freenode.org)

## logstash

You should download the logstash 'monolithic' jar - if you haven't yet, [download it now](http://semicomplete.com/files/logstash/logstash-%VERSION%-monolithic.jar). This package includes most
of the dependencies for logstash in it and helps you get started quicker.

The configuration of any logstash agent consists of specifying inputs, filters,
and outputs. For this example, we will not configure any filters.

The inputs are your log files. The output will be elasticsearch. The config
format should be simple to read and write. The bottom of this document includes
links for further reading (config, etc) if you want to learn more.

Here is a sample config you can start with. It defines some basic inputs
grouped by type and two outputs.

    input {
      file {
        type => "linux-syslog"

        # Wildcards work, here :)
        path => [ "/var/log/*.log", "/var/log/messages", "/var/log/syslog" ]
      }

      file {
        type => "apache-access"
        path => "/var/log/apache2/access.log"
      }

      file {
        type => "apache-error"
        path => "/var/log/apache2/error.log"
      }
    }

    output {
      # Emit events to stdout for easy debugging of what is going through
      # logstash.
      stdout { }

      # This will use elasticsearch to store your logs.
      # The 'embedded' option will cause logstash to run the elasticsearch
      # server in the same process, so you don't have to worry about
      # how to download, configure, or run elasticsearch!
      elasticsearch { embedded => true }
    }

Put this in a file called "mylogstash.conf"

Now run it all:

    java -jar logstash-%VERSION%-monolithic.jar agent -f mylogstash.conf -- web --backend elasticsearch:///?local

Point your browser at <http://yourserver:9292> and start searching!

## Futher reading

Want to know more about the configuration language? Check out the
[configuration](configuration) documentation.

You may have logs on many servers you want to centralize through logstash. To
learn how to do that, [read this](getting-started-centralized)
