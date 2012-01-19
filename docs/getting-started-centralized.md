---
title: Getting Started (Centralized Server) - logstash
layout: content_right
---

# Getting Started

## Centralized Setup with Event Parsing

This guide shows how to get you going quickly with logstash with multiple
servers. This guide is for folks who want to ship all their logstash logs to a
central location for indexing and search.

We'll have two classes of server. First, one that ships logs. Second, one that
collects and indexes logs.

It's important to note that logstash itself has no concept of "shipper" and
"collector" - the behavior of an agent depends entirely on how you configure
it.

On servers shipping logs:

* Download and run logstash (See section 'logstash log shipper' below)

On the server collecting and indexing your logs:

* Download and run elasticsearch
* Download and run an AMQP broker
* Download and run logstash

## ElasticSearch

Requirements: java

You'll most likely want the version of ElasticSearch specified by the
<outputs/elasticsearch> docs. Modify this in your shell for easy downloading of
ElasticSearch:

    ES_PACKAGE=elasticsearch-0.17.6.zip
    ES_DIR=${ES_PACKAGE%%.zip}
    SITE=https://github.com/downloads/elasticsearch/elasticsearch
    if [ ! -d "$ES_DIR" ] ; then
      wget --no-check-certificate $SITE/$ES_PACKAGE
      unzip $ES_PACKAGE
    fi

ElasticSearch requires Java (uses Lucene on the backend; if you want to know
more read the elasticsearch docs).

To start the service, run `bin/elasticsearch`. If you want to run it in the
foreground, use 'bin/elasticsearch -f' 

## AMQP Broker

AMQP is a standard for message-based communication. It supports
publish-subscribe, queues, etc.  AMQP is supported way to ship your logs
between servers with logstash. You could also use redis, xmpp, stomp, tcp, or
other means to transport your logs.

If you don't know what AMQP is, that's fine, you don't need to know anything
about it for this config. If you already have an AMQP server and know how to
configure it, you can skip this section.

If you don't have an AMQP server already, you might as well download [rabbitmq
http://www.rabbitmq.com/server.html] I recommend using the native packages
(rpm, deb) if those are available for your system.

Configuring RabbitMQ is out of scope for this doc, but know that if you use the
RPM or Deb package you'll probably end up with a rabbitmq startup script that
you can use, and you'll be ready to go to the next section.

If you want/need to configure RabbitMQ, seek the rabbitmq docs.

## logstash

Once you have elasticsearch and rabbitmq (or any AMQP server) running, you're
ready to configure logstash.

Download the monolithic logstash release package. By 'monolithic' I mean the
package contains all required dependencies to save you time chasing down
requirements.

You can download the latest release on the [front page](/)

Since we're doing a centralized configuration, you'll have two main logstash
agent roles: a shipper and an indexer. You will ship logs from all servers to a
single AMQP message queue and have another agent receive those messages, parse
them, and index them in elasticsearch.

### logstash log shipper

This agent you will run on all of your servers you want to collect logs on.
Here's a good sample config:

    input {
      file {
        type => "syslog"

        # Wildcards work here :)
        path => [ "/var/log/messages", "/var/log/syslog", "/var/log/*.log" ]
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
      # Output events to stdout for debugging. Feel free to remove
      # this output if you don't need it.
      stdout { }

      # Ship events to the amqp fanout exchange named 'rawlogs"
      amqp {
        host => "myamqpserver"
        exchange_type => "fanout"
        name => "rawlogs"
      }
    }

Put this in a file and call it 'myshipper.conf' (or anything, really), and run: 

    java -jar logstash-%VERSION%-monolithic.jar agent -f myshipper.conf

This should start tailing the file inputs specified above and ships them out
over amqp. If you included the 'stdout' output you will see events written to
stdout as they are found.

### logstash indexer

This agent will parse and index your logs as they come in over AMQP. Here's a
sample config based on the previous section.

We'll use grok to parse some logs. Grok is a filter in logstash. Additionally,
after we parse with grok, we want to take any timestamps found in the log and
parse them to use as the real timestamp value for the event.

    input {
      amqp {
        # ship logs to the 'rawlogs' fanout queue.
        type => "all"
        host => "myamqpserver"
        exchange => "rawlogs"
        name => "rawlogs_consumer"
      }
    }

    filter {
      grok {
        type => "syslog" # for logs of type "syslog"
        pattern => "%{SYSLOGLINE}"
        # You can specify multiple 'pattern' lines
      }

      grok {
        type => "apache-access" # for logs of type 'apache-access'
        pattern => "%{COMBINEDAPACHELOG}"
      }

      date {
        type => "syslog"

        # The 'timestamp' and 'timestamp8601' names are for fields in the
        # logstash event.  The 'SYSLOGLINE' grok pattern above includes a field
        # named 'timestamp' that is set to the normal syslog timestamp if it
        # exists in the event.
        timestamp => "MMM  d HH:mm:ss"   # syslog 'day' value can be space-leading
        timestamp => "MMM dd HH:mm:ss"
        timestamp8601 => ISO8601 # Some syslogs use ISO8601 time format
      }

      date {
        type => "apache-access"
        timestamp => "dd/MMM/yyyy:HH:mm:ss Z"
      }
    }
    
    output {
      stdout { }

      # If your elasticsearch server is discoverable with multicast, use this:
      #elasticsearch { }

      # If you can't discover using multicast, set the address explicitly
      elasticsearch {
        host => "myelasticsearchserver"
      }
    }


The above config will take raw logs in over amqp, parse them with grok and date
filters, and index them into elasticsearch.

## logstash web interface

Run this on the same server as your elasticsearch server.

To run the logstash web server, just run the jar with 'web' as the first
argument. 

    % java -jar logstash-%VERSION%-monolithic.jar web
    >> Thin web server (v1.2.7 codename No Hup)
    >> Maximum connections set to 1024
    >> Listening on 0.0.0.0:9292, CTRL+C to stop

Just point your browser at the http://yourserver:9292/ and start searching
logs!

Note: If your elasticsearch server is not discoverable with multicast, you can
specify the host explicitly using the --backend flag:

    % java -jar logstash-%VERSION%-monolithic.jar web --backend elasticsearch://myserver/

If you set a cluster name in ElasticSearch (ignore this if you don't know what
that means), you must give the cluster name to logstash as well: --backend
elasticsearch://myserver/clustername
