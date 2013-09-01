---
title: the life of an event - logstash
layout: content_right
---
# the life of an event

The logstash agent is an event pipeline.

## The Pipeline

The logstash agent is a processing pipeline with 3 stages: inputs -> filters ->
outputs. Inputs generate events, filters modify them, outputs ship them
elsewhere.

Internal to logstash, events are passed from each phase using internal queues.
It is implemented with a 'SizedQueue' in Ruby. SizedQueue allows a bounded
maximum of items in the queue such that any writes to the queue will block if
the queue is full at maximum capacity.

Logstash sets each queue size to 20. This means only 20 events can be pending
into the next phase - this helps reduce any data loss and in general avoids
logstash trying to act as a data storage system. These internal queues are not
for storing messages long-term.

## Fault Tolerance

Starting at outputs, here's what happens when things break.

An output can fail or have problems because of some downstream cause, such as
full disk, permissions problems, temporary network failures, or service
outages. Most outputs should keep retrying to ship any events that were
involved in the failure.

If an output is failing, the output thread will wait until this output is
healthy again and able to successfully send the message. Therefore, the output
queue will stop being read from by this output and will eventually fill up with
events and block new events from being written to this queue.

A full output queue means filters will block trying to write to the output
queue. Because filters will be stuck, blocked writing to the output queue, they
will stop reading from the filter queue which will eventually cause the filter
queue (input -> filter) to fill up.

A full filter queue will cause inputs to block when writing to the filters.
This will cause each input to block, causing each input to stop processing new
data from wherever that input is getting new events.

In ideal circumstances, this will behave similarly to when the tcp window
closes to 0, no new data is sent because the receiver hasn't finished
processing the current queue of data, but as soon as the downstream (output)
problem is resolved, messages will begin flowing again..

## Thread Model

The thread model in logstash is currently:

    input threads | filter worker threads | output worker

Filters are optional, so you will have this model if you have no filters
defined:

    input threads | output worker

Each input runs in a thread by itself. This allows busier inputs to not be
blocked by slower ones, etc. It also allows for easier containment of scope
because each input has a thread.

The filter thread model is a 'worker' model where each worker receives an event
and applies all filters, in order, before emitting that to the output queue.
This allows scalability across CPUs because many filters are CPU intensive
(permitting that we have thread safety). 

The default number of filter workers is 1, but you can increase this number
with the '-w' flag on the agent.

The output worker model is currently a single thread. Outputs will receive
events in the order they are defined in the config file. 

Outputs may decide to buffer events temporarily before publishing them,
possibly in a separate thread. One example of this is the elasticsearch output
which will buffer events and flush them all at once, in a separate thread. This
mechanism (buffering many events + writing in a separate thread) can improve
performance so the logstash pipeline isn't stalled waiting for a response from
elasticsearch.

## Consequences and Expectations

Small queue sizes mean that logstash simply blocks and stalls safely during
times of load or other temporary pipeline problems. There are two alternatives
to this - unlimited queue length and dropping messages. Unlimited queues grow
grow unbounded and eventually exceed memory causing a crash which loses all of
those messages. Dropping messages is also an undesirable behavior in most cases.

At a minimum, logstash will have probably 3 threads (2 if you have no filters).
One input, one filter worker, and one output thread each.

If you see logstash using multiple CPUs, this is likely why. If you want to
know more about what each thread is doing, you should read this:
<http://www.semicomplete.com/blog/geekery/debugging-java-performance.html>.

Threads in java have names, and you can use jstack and top to figure out who is
using what resources. The URL above will help you learn how to do this.

On Linux platforms, logstash will label all the threads it can with something
descriptive. Inputs will show up as "<inputname" and filter workers as
"|worker" and outputs as ">outputworker" (or something similar).  Other threads
may be labeled as well, and are intended to help you identify their purpose
should you wonder why they are consuming resources!

