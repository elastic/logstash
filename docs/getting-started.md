---
title: Getting Started (Standalone server) - logstash
layout: default
---
# Getting started with logstash (standalone server example)

This guide shows how to get you going quickly with logstash on a single,
standalone server collecting its own logs. By standalone, I mean that
everything happens on a single server: log collection, indexing, and the web
interface.

logstash can be run on multiple servers (collect from many servers to a single
indexer) if you want, but this example shows simply a standalone configuration.

Steps:

* Download and run elasticsearch </li>
* Download and run logstash </li>

## Problems?

If you have problems, feel free to email the users list
(logstash-users@googlegroups.com) or join IRC (#logstash on irc.freenode.org)

## ElasticSearch

Requirements: Java. I have only tested with sun java.

Use this shell scriptlet to help download and unpack elasticsearch:

    ES_PACKAGE=elasticsearch-0.16.0.zip
    ES_DIR=${ES_PACKAGE%%.zip}
    if [ ! -d "$ES_DIR" ] ; then
      wget --no-check-certificate http://github.com/downloads/elasticsearch/elasticsearch/$ES_PACKAGE
      unzip $ES_PACKAGE
    fi

Otherwise: Download and unpack the elasticsearch yourself; you'll want version
0.16.0 or newer. It's written in Java and requires Java (uses Lucene on the
backend; if you want to know more read the <a href="http://elasticsearch.org">elasticsearch docs</a>).

To start the service, run bin/elasticsearch. If you want to run it in the
foreground, use `bin/elasticsearch -f`

## logstash

Once you have elasticsearch running, you're ready to configure logstash.

You should download the logstash 'monolithic' jar. This package includes most
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

      # This elasticsearch output will try to autodiscover a near-by
      # elasticsearch cluster using multicast discovery.
      # If multicast doesn't work, you'll need to set a 'host' setting.
      elasticsearch { }
    }

Put this in a file called "mylogstash.conf"

Now run 

    java -jar logstash-1.0-monolithic.jar agent -f mylogstash.conf

## the web interface

To run the logstash web ui, run this:

    java -jar logstash-1.0-monolithic.jar web

Point your browser at <http://yourserver:9292> and start searching!

