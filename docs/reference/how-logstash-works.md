---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/pipeline.html
---

# How Logstash Works [pipeline]

The Logstash event processing pipeline has three stages: inputs → filters → outputs. Inputs generate events, filters modify them, and outputs ship them elsewhere. Inputs and outputs support codecs that enable you to encode or decode the data as it enters or exits the pipeline without having to use a separate filter.


## Inputs [_inputs]

You use inputs to get data into Logstash. Some of the more commonly-used inputs are:

* **file**: reads from a file on the filesystem, much like the UNIX command `tail -0F`
* **syslog**: listens on the well-known port 514 for syslog messages and parses according to the RFC3164 format
* **redis**: reads from a redis server, using both redis channels and redis lists. Redis is often used as a "broker" in a centralized Logstash installation, which queues Logstash events from remote Logstash "shippers".
* **beats**: processes events sent by [Beats](https://www.elastic.co/downloads/beats).

For more information about the available inputs, see [Input Plugins](logstash-docs-md://lsr/input-plugins.md).


## Filters [_filters]

Filters are intermediary processing devices in the Logstash pipeline. You can combine filters with conditionals to perform an action on an event if it meets certain criteria. Some useful filters include:

* **grok**: parse and structure arbitrary text. Grok is currently the best way in Logstash to parse unstructured log data into something structured and queryable. With 120 patterns built-in to Logstash, it’s more than likely you’ll find one that meets your needs!
* **mutate**: perform general transformations on event fields. You can rename, remove, replace, and modify fields in your events.
* **drop**: drop an event completely, for example, *debug* events.
* **clone**: make a copy of an event, possibly adding or removing fields.
* **geoip**: add information about geographical location of IP addresses (also displays amazing charts in Kibana!)

For more information about the available filters, see [Filter Plugins](logstash-docs-md://lsr/filter-plugins.md).


## Outputs [_outputs]

Outputs are the final phase of the Logstash pipeline. An event can pass through multiple outputs, but once all output processing is complete, the event has finished its execution. Some commonly used outputs include:

* **elasticsearch**: send event data to Elasticsearch. If you’re planning to save your data in an efficient, convenient, and easily queryable format… Elasticsearch is the way to go. Period. Yes, we’re biased :)
* **file**: write event data to a file on disk.
* **graphite**: send event data to graphite, a popular open source tool for storing and graphing metrics. [http://graphite.readthedocs.io/en/latest/](http://graphite.readthedocs.io/en/latest/)
* **statsd**: send event data to statsd, a service that "listens for statistics, like counters and timers, sent over UDP and sends aggregates to one or more pluggable backend services". If you’re already using statsd, this could be useful for you!

For more information about the available outputs, see [Output Plugins](logstash-docs-md://lsr/output-plugins.md).


## Codecs [_codecs]

Codecs are basically stream filters that can operate as part of an input or output. Codecs enable you to easily separate the transport of your messages from the serialization process. Popular codecs include `json`, `msgpack`, and `plain` (text).

* **json**: encode or decode data in the JSON format.
* **multiline**: merge multiple-line text events such as java exception and stacktrace messages into a single event.

For more information about the available codecs, see [Codec Plugins](logstash-docs-md://lsr/codec-plugins.md).




