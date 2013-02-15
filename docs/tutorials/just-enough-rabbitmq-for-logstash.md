---
title: Just Enough RabbitMQ - logstash
layout: content_right
---

While configuring your RabbitMQ broker is out of scope for logstash, it's important
to understand how logstash uses RabbitMQ. To do that, we need to understand a
little about AMQP.

You should also consider reading
[this](http://www.rabbitmq.com/tutorials/amqp-concepts.html) at the RabbitMQ
website.

# Exchanges, queues and bindings; OH MY!

You can get a long way by understanding a few key terms.

## Exchanges

Exchanges are for message **producers**. In Logstash, we map these to
**outputs**.  Logstash puts messages on exchanges.  There are many types of
exchanges and they are discussed below.

## Queues

Queues are for message **consumers**. In Logstash, we map these to inputs.
Logstash reads messages from queues.  Optionally, queues can consume only a
subset of messages. This is done with "routing keys".

## Bindings

Just having a producer and a consumer is not enough. We must `bind` a queue to
an exchange.  When we bind a queue to an exchange, we can optionally provide a
routing key.  Routing keys are discussed below.

## Broker

A broker is simply the AMQP server software. There are several brokers, but this
tutorial will cover the most common (and arguably popular), [RabbitMQ](http://www.rabbitmq.com).

# Routing Keys

Simply put, routing keys are somewhat like tags for messages. In practice, they
are hierarchical in nature with the each level separated by a dot:

- `messages.servers.production`
- `sports.atlanta.baseball`
- `company.myorg.mydepartment`

Routing keys are really handy with a tool like logstash where you
can programatically define the routing key for a given event using the metadata that logstash provides:

- `logs.servers.production.host1`
- `logs.servers.development.host1.syslog`
- `logs.servers.application_foo.critical`

From a consumer/queue perspective, routing keys also support two types wildcards - `#` and `*`.

- `*` (asterisk) matches any single word.
- `#` (hash) matches any number of words and behaves like a traditional wildcard.

Using the above examples, if you wanted to bind to an exchange and see messages
for just production, you would use the routing key `logs.servers.production.*`.
If you wanted to see messages for host1, regardless of environment you could
use `logs.servers.%.host1.#`.

Wildcards can be a bit confusing but a good general rule to follow is to use
`*` in places where you need wildcards for a known element.  Use `#` when you
need to match any remaining placeholders. Note that wildcards in routing keys
only make sense on the consumer/queue binding, not in the publishing/exchange
side.

We'll get into some of that neat stuff below. For now, it's enough to
understand the general idea behind routing keys.

# Exchange types

There are three primary types of exchanges that you'll see.

## Direct

A direct exchange is one that is probably most familiar to people. Message
comes in and, assuming there is a queue bound, the message is picked up.  You
can have multiple queues bound to the same direct exchange. The best way to
understand this pattern is pool of workers (queues) that read from a direct
exchange to get units of work. Only one consumer will see a given message in a
direct exchange.

You can set routing keys on messages published to a direct exchange. This
allows you do have workers that do different tasks read from the same global
pool of messages yet consume only the ones they know how to handle.

The RabbitMQ concepts guide (linked below) does a good job of describing this
visually
[here](http://www.rabbitmq.com/img/tutorials/intro/exchange-direct.png)

## Fanout

Fanouts are another type of exchange. Unlike direct exchanges, every queue
bound to a fanout exchange will see the same messages.  This is best described
as a PUB/SUB pattern. This is helpful when you need broadcast messages to
multiple interested parties.

Fanout exchanges do NOT support routing keys. All bound queues see all
messages.

## Topic

Topic exchanges are special type of fanout exchange. Fanout exchanges don't
support routing keys. Topic exchanges do support them.  Just like a fanout
exchange, all bound queues see all messages with the additional filter of the
routing key.

# RabbitMQ in logstash

As stated earlier, in Logstash, Outputs publish to Exchanges. Inputs read from
Queues that are bound to Exchanges.  Logstash uses the `bunny` RabbitMQ library for
interaction with a broker. Logstash endeavors to expose as much of the
configuration for both exchanges and queues.  There are many different tunables
that you might be concerned with setting - including things like message
durability or persistence of declared queues/exchanges.  See the relevant input
and output documentation for RabbitMQ for a full list of tunables.

# Sample configurations, tips, tricks and gotchas

There are several examples in the logstash source directory of RabbitMQ usage,
however a few general rules might help eliminate any issues.

## Check your bindings

If logstash is publishing the messages and logstash is consuming the messages,
the `exchange` value for the input should match the `name` in the output.

sender agent

    input { stdin { type = "test" } }
    output {
      rabbitmq {
        exchange => "test_exchange"
        host => "my_rabbitmq_server"
        exchange_type => "fanout"
      }
    }

receiver agent

    input {
      rabbitmq {
        queue => "test_queue"
        host => "my_rabbitmq_server"
        exchange => "test_exchange" # This matches the exchange declared above
      }
    }
    output { stdout { debug => true }}

## Message persistence

By default, logstash will attempt to ensure that you don't lose any messages.
This is reflected in the RabbitMQ default settings as well.  However there are
cases where you might not want this. A good example is where RabbitMQ is not your
primary method of shipping.

In the following example, we use RabbitMQ as a sniffing interface. Our primary
destination is the embedded ElasticSearch instance. We have a secondary RabbitMQ
output that we use for duplicating messages. However we disable persistence and
durability on this interface so that messages don't pile up waiting for
delivery. We only use RabbitMQ when we want to watch messages in realtime.
Additionally, we're going to leverage routing keys so that we can optionally
filter incoming messages to subsets of hosts. The exercise of getting messages
to this logstash agent are left up to the user.

    input { 
      # some input definition here
    }

    output {
      elasticsearch { embedded => true }
      rabbitmq {
        exchange => "logtail"
        host => "my_rabbitmq_server"
        exchange_type => "topic" # We use topic here to enable pub/sub with routing keys
        key => "logs.%{host}"
        durable => false # If rabbitmq restarts, the exchange disappears.
        auto_delete => true # If logstash disconnects, the exchange goes away
        persistent => false # Messages are not persisted to disk
      }
    }

Now if you want to stream logs in realtime, you can use the programming
language of your choice to bind a queue to the `logtail` exchange.  If you do
not specify a routing key, you will see every message that comes in to
logstash. However, you can specify a routing key like `logs.apache1` and see
only messages from host `apache1`.

Note that any logstash variable is valid in the key definition. This allows you
to create really complex routing key hierarchies for advanced filtering.

Note that RabbitMQ has specific rules about durability and persistence matching
on both the queue and exchange. You should read the RabbitMQ documentation to
make sure you don't crash your RabbitMQ server with messages awaiting someone
to pick them up.
