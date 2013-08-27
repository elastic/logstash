---
title: ZeroMQ - logstash
layout: content_right
---

*ZeroMQ support in Logstash is currently in an experimental phase. As such, parts of this document are subject to change.*

# ZeroMQ
Simply put ZeroMQ (0mq) is a socket on steroids. This makes it a perfect compliment to Logstash - a pipe on steroids.

ZeroMQ allows you to easily create sockets of various types for moving data around. These sockets are refered to in ZeroMQ by the behavior of each side of the socket pair:

* PUSH/PULL
* REQ/REP
* PUB/SUB
* ROUTER/DEALER

There is also a `PAIR` socket type as well.

Additionally, the socket type is independent of the connection method. A PUB/SUB socket pair could have the SUB side of the socket be a listener and the PUB side a connecting client. This makes it very easy to fit ZeroMQ into various firewalled architectures.

Note that this is not a full-fledged tutorial on ZeroMQ. It is a tutorial on how Logstash uses ZeroMQ.

# ZeroMQ and logstash
In the spirit of ZeroMQ, Logstash takes these socket type pairs and uses them to create topologies with some very simply rules that make usage very easy to understand:

* The receiving end of a socket pair is always a logstash input
* The sending end of a socket pair is always a logstash output
* By default, inputs `bind`/listen and outputs `connect`
* Logstash refers to the socket pairs as topologies and mirrors the naming scheme from ZeroMQ
* By default, ZeroMQ inputs listen on all interfaces on port 2120, ZeroMQ outputs connect to `localhost` on port 2120

The currently understood Logstash topologies for ZeroMQ inputs and outputs are:

* `pushpull`
* `pubsub`
* `pair`

We have found from various discussions that these three topologies will cover most of user's needs. We hope to expose the full span of ZeroMQ socket types as time goes on.

By keeping the options simple, this allows you to get started VERY easily with what are normally complex message flows. No more confusion over `exchanges` and `queues` and `brokers`. If you need to add fanout capability to your flow, you can simply use the following configs:

* _node agent lives at 192.168.1.2_
* _indexer agent lives at 192.168.1.1_

    # Node agent config
    input { stdin { type => "test-stdin-input" } }
    output { zeromq { topology => "pubsub" address => "tcp://192.168.1.1.:2120" } }

    # Indexer agent config
    input { zeromq { topology => "pubsub" } }
    output { stdout { debug => true }}

If for some reason you need connections to initiate from the indexer because of firewall rules:

    # Node agent config - now listening on all interfaces port 2120
    input { stdin { type => "test-stdin-input" } }
    output { zeromq { topology => "pubsub" address => "tcp://*.:2120" mode => "server" } }

    # Indexer agent config
    input { zeromq { topology => "pubsub" address => "tcp://192.168.1.2" mode => "client" } }
    output { stdout { debug => true }}

As stated above, by default `inputs` always start as listeners and `outputs` always start as initiators. Please don't confuse what happens once the socket is connect with the direction of the connection. ZeroMQ separates connection from topology. In the second case of the above configs, once the two sockets are connected, regardless of who initiated the connection, the message flow itself is absolute. The indexer is reading events from the node.

# Which topology to use
The choice of topology can be broken down very easily based on need

## one to one
Use `pair` topology. On the output side, specify the ipaddress and port of the input side.

## broadcast
Use `pubsub`
If you need to broadcast ALL messages to multiple hosts that each need to see all events, use `pubsub`. Note that all events are broadcast to all subscribers. When using `pubsub` you might also want to investigate the `topic` configuration option which allows subscribers to see only a subset of messages.

## Filter workers
Use `pushpull`
In `pushpull`, ZeroMQ automatically load balances to all connected peers. This means that no peer sees the same message as any other peer.

# What's with the address format?
ZeroMQ supports multiple types of transports:

* inproc:// (unsupported by logstash due to threading)
* tcp:// (exactly what it sounds like)
* ipc:// (probably useless in logstash)
* pgm:// and epgm:// (a multicast format - only usable with PUB and SUB socket types)

For pretty much all cases, you'll be using `tcp://` transports with Logstash.

## Topic - applies to `pubsub`
This opt mimics the routing keys functionality in AMQP. Imagine you have a network of receivers but only a subset of the messages need to be seen by a subset of the hosts. You can use this option as a routing key to facilite that:

    # This output is a PUB
    output {
    zeromq { topology => "pubsub" topic => "logs.production.%{host}" }
    }

    # This input is a SUB
    # I only care about db1 logs
    input { zeromq { type => "db1logs" address => "tcp://<ipaddress>:2120" topic => "logs.production.db1"}}

One thing important to note about 0mq PUBSUB and topics is that all filtering is done on the subscriber side. The subscriber will get ALL messages but discard any that don't match the topic.

Also important to note is that 0mq doesn't do topic in the same sense as an AMQP broker might. When a SUB socket gets a message, it compares the first bytes of the message against the topic. However, this isn't always flexible depending on the format of your message. The common practice then, is to send a 0mq multipart message and make the first part the topic. The next parts become the actual message body.

This is approach is how logstash handles this. When using PUBSUB, Logstash will send a multipart message where the first part is the name of the topic and the second part is the event. This is important to know if you are sending to a SUB input from sources other than Logstash.

# sockopts
Sockopts is not you choosing between blue or black socks. ZeroMQ supports setting various flags or options on sockets. In the interest of minimizing configuration syntax, these are _hidden_ behind a logstash configuration element called `sockopts`. You probably won't need to tune these for most cases. If you do need to tune them, you'll probably set the following:

## ZMQ::HWM - sets the high water mark
The high water mark is the maximum number of messages a given socket pair can have in its internal queue. Use this to throttle essentially.

## ZMQ::SWAP_SIZE
TODO

## ZMQ::IDENTITY
TODO
