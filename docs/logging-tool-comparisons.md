---
title: Logging tools comparisons - logstash
layout: content_right
---
# Logging tools comparison

The information below is provided as "best effort" and is not strictly intended
as a complete source of truth. If the information below is unclear or incorrect, please
email the logstash-users list (or send a pull request with the fix) :)

Where feasible, this document will also provide information on how you can use
logstash with these other projects.

# logstash

Primary goal: Make log/event data and analytics accessible.

Overview: Where your logs come from, how you store them, or what you do with
them is up to you. Logstash exists to help make such actions easier and faster.

It provides you a simple event pipeline for taking events and logs from any
input, manipulating them with filters, and sending them to any output. Inputs
can be files, network, message brokers, etc. Filters are date and string
parsers, grep-like, etc. Outputs are data stores (elasticsearch, mongodb, etc),
message systems (rabbitmq, stomp, etc), network (tcp, syslog), etc.

It also provides a web interface for doing search and analytics on your
logs.

# graylog2

[http://graylog2.org/](http://graylog2.org)

_Overview to be written_

You can use graylog2 with logstash by using the 'gelf' output to send logstash
events to a graylog2 server. This gives you logstash's excellent input and
filter features while still being able to use the graylog2 web interface.

# whoops

[whoops site](http://www.whoopsapp.com/)

_Overview to be written_

A logstash output to whoops is coming soon - <https://logstash.jira.com/browse/LOGSTASH-133>

# flume

[flume site](https://github.com/cloudera/flume/wiki)

Flume is primarily a transport system aimed at reliably copying logs from
application servers to HDFS.

You can use it with logstash by having a syslog sink configured to shoot logs
at a logstash syslog input.

# scribe

_Overview to be written_
