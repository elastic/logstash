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

This diagram gives you an overview of the architecture:

![Centralized setup overview](getting-started-centralized-overview-diagram.png)

On servers shipping logs:

* Download and run logstash (See section 'logstash log shipper' below)

On the server collecting and indexing your logs:

* Download and run Elasticsearch
* Download and run Redis
* Download and run Logstash

## ElasticSearch

Requirements: java

You'll most likely want the version of ElasticSearch specified by the
[elasticsearch output](../outputs/elasticsearch) docs. Modify this in your shell
for easy downloading of ElasticSearch:

    ES_PACKAGE=elasticsearch-0.90.3.zip
    ES_DIR=${ES_PACKAGE%%.zip}
    SITE=https://download.elasticsearch.org/elasticsearch/elasticsearch
    if [ ! -d "$ES_DIR" ] ; then
      wget --no-check-certificate $SITE/$ES_PACKAGE
      unzip $ES_PACKAGE
    fi

ElasticSearch requires Java (uses Lucene on the backend; if you want to know
more read the elasticsearch docs).

To start the service, run `bin/elasticsearch -f`. This will run it in the foreground. We want to keep it this way for debugging for now.

## Redis

Previous versions of this guide used AMQP via RabbitMQ. Due to the complexity of AMQP as well as performance issues related to the Bunny driver we use, we're now recommending Redis instead.

Redis has no external dependencies and has a much simpler configuration in Logstash.

Building and installing Redis is fairly straightforward. While normally this would be out of the scope of this document, as the instructions are so simple we'll include them here:

- Download Redis from http://redis.io/download (The latest stable release is likely what you want)
- Extract the source, change to the directory and run `make`
- Run Redis with `src/redis-server --loglevel verbose`

That's it.

## logstash

Once you have elasticsearch and redis running, you're
ready to configure logstash.

Download the logstash release jar file. The package contains all
required dependencies to save you time chasing down requirements.

Follow [this link to download logstash-1.2.0.beta1](http://logstash.objects.dreamhost.com/release/logstash-1.2.0.beta1-flatjar.jar).

Since we're doing a centralized configuration, you'll have two main
logstash agent roles: a shipper and an indexer. You will ship logs from
all servers via Redis and have another agent receive those messages,
parse them, and index them in elasticsearch.

### logstash log shipper

As with the simple example, we're going to start simple to ensure that events are flowing

    input {
      stdin {
        type => "stdin-type"
      }
    }

    output {
      stdout { debug => true debug_format => "json"}
      redis { host => "127.0.0.1" data_type => "list" key => "logstash" }
    }

Put this in a file and call it 'shipper.conf' (or anything, really), and run: 

    java -jar logstash-1.2.0.beta1-flatjar.jar agent -f shipper.conf

This will take anything you type into this console and display it on the console. Additionally it will save events to Redis in a `list` named after the `key` value you provided.

### Testing the Redis output

To verify that the message made it into Redis, check your Redis window. You should see something like the following:

    [83019] 02 Jul 12:51:02 - Accepted 127.0.0.1:58312
    [83019] 02 Jul 12:51:06 - Client closed connection
    [83019] 02 Jul 12:51:06 - DB 0: 1 keys (0 volatile) in 4 slots HT.

The redis application ships with a CLI application that you can use to query the data. From your Redis source directory, run the following:

`src/redis-cli`

Once connected, run the following commands:

    redis 127.0.0.1:6379> llen logstash
    (integer) 1
    redis 127.0.0.1:6379> lpop logstash
    "{\"@source\":\"stdin://jvstratusmbp.local/\",\"@type\":\"stdin-type\",\"@tags\":[],\"@fields\":{},\"@timestamp\":\"2012-07-02T17:01:12.278000Z\",\"@source_host\":\"jvstratusmbp.local\",\"@source_path\":\"/\",\"@message\":\"test\"}"
    redis 127.0.0.1:6379> llen logstash
    (integer) 0
    redis 127.0.0.1:6379>

What we've just done is check the length of the list, read and removed the oldest item in the list, and checked the length again.

This behavior is what Logstash does when it reads from a Redis input (technically logstash performs a blocking lpop). We're essentially using Redis to simulate a queue via the `list` data type.

Go ahead and type a few more entries in the agent window:

- test 1
- test 2
- test 3

As you `lpop` you should get them in the correct order of insertion.

### logstash indexer

This agent will parse and index your logs as they come in over Redis. Here's a
sample config based on the previous section. Save this as `indexer.conf`

    input {
      redis {
        host => "127.0.0.1"
        type => "redis-input"
        # these settings should match the output of the agent
        data_type => "list"
        key => "logstash"

        # We use json_event here since the sender is a logstash agent
        format => "json_event"
      }
    }
    
    output {
      stdout { debug => true debug_format => "json"}

      elasticsearch {
        host => "127.0.0.1"
      }
    }

The above configuration will attach to Redis and issue a `BLPOP` against the `logstash` list. When an event is recieved, it will be pulled off and sent to Elasticsearch for indexing.

Start the indexer the same way as the agent but specifying the `indexer.conf` file:

`java -jar logstash-1.2.0.beta1-flatjar.jar agent -f indexer.conf`

To verify that your Logstash indexer is connecting to Elasticsearch properly, you should see a message in your Elasticsearch window similar to the following:

`[2012-07-02 13:14:27,008][INFO ][cluster.service          ] [Baron Samedi] added {[Bes][JZQBMR21SUWRNtTMsDV3_g][inet[/192.168.1.194:9301]]{client=true, data=false},}`

The names `Bes` and `Baron Samedi` may differ as ES uses random names for nodes.

### Testing the flow
Now we want to test the flow. In your agent window, type something to generate an event.
The indexer should read this and persist it to Elasticsearch. It will also display the event to stdout.

In your Elasticsearch window, you should see something like the following:

    [2012-07-02 13:21:58,982][INFO ][cluster.metadata         ] [Baron Samedi] [logstash-2012.07.02] creating index, cause [auto(index api)], shards [5]/[1], mappings []
    [2012-07-02 13:21:59,495][INFO ][cluster.metadata         ] [Baron Samedi] [logstash-2012.07.02] update_mapping [stdin-type] (dynamic)

Since indexes are created dynamically, this is the first sign that Logstash was able to write to ES. Let's use curl to verify our data is there:
Using our curl command from the simple tutorial should let us see the data:

`curl -s -XGET http://localhost:9200/logstash-2012.07.02/_search?q=@type:stdin-type`

You may need to modify the date as this is based on the date this guide was written.

Now we can move on to the final step...
## logstash web interface

Run this on the same server as your elasticsearch server.

To run the logstash web server, just run the jar with 'web' as the first
argument. 

    java -jar logstash-1.2.0.beta1-flatjar.jar web

Just point your browser at the http://127.0.0.1:9292/ and start searching
logs!

The web interface is called 'kibana' - you can learn more about kibana at <http://kibana.org>

# Distributing the load
At this point we've been simulating a distributed environment on a single machine. If only the world were so easy.
In all of the example configurations, we've been explicitly setting the connection to connect to `127.0.0.1` despite the fact in most network-related plugins, that's the default host.

Since Logstash is so modular, you can install the various components on different systems.

- If you want to give Redis a dedicated host, simply ensure that the `host` attribute in configurations points to that host.
- If you want to give Elasticsearch a dedicated host, simple ensure that the `host` attribute is correct as well (in both web and indexer).

As with the simple input example, reading from stdin is fairly useless. Check the Logstash documentation for the various inputs offered and mix and match to taste!
