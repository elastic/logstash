---
title: the life of an event - logstash
layout: content_right
---
# the life of an event

The logstash agent is an event pipeline.

The logstash agent is 3 parts: inputs -> filters -> outputs. Inputs generate
events, filters modify them, outputs ship them elsewhere.

Internal to logstash, events are passed from each phase using internal queues.
It is implemented with a 'SizedQueue' in Ruby. SizedQueue allows a bounded
maximum of items in the queue such that any writes to the queue will block if
the queue is full at maximum capacity.

Logstash sets each queue size to 20. This means only 20 events can be pending
into the next phase - this helps reduce any data loss and in general avoids
logstash trying to act as a data storage system. These internal queues are not
for storing messages long-term.

Starting at outputs, here's what happens with a queue fills up.

If an output is failing, the output thread will wait until this output is
healthy again and able to successfully send the message. Therefore, the output
queue will stop being read from by this output and will eventually fill up with
events and cause write blocks.

A full output queue means filters will block trying to write to the output
queue. Because filters will be stuck, blocked writing to the output queue, they
will stop reading from the filter queue which will eventually cause the filter
queue (input -> filter) to fill up.

A full filter queue will cause inputs to block when writing to the filters.
This will cause each input to block, causing each input to stop processing new
data from wherever that input is getting new events.

In ideal circumstances, this will behave similarly to when the tcp window
closes to 0, no new data is sent because the receiver hasn't finished
processing the current queue of data.

## Thread Model

The thread model in logstash is currently:

    input threads | filter threads | output threads

Filters are optional, so you will have this model if you have no filters defined:

    input threads | output threads

Each input runs in a thread by itself. This allows busier inputs to not be
blocked by slower ones, etc. It also allows for easier containment of scope
because each input has a thread.

The filter thread model is a 'worker' model where each worker receives an event
and applies all filters, in order, before emitting that to the output queue.
This allows scalability across CPUs because many filters are CPU intensive
(permitting that we have thread safety). Currently, logstash forces the number
of filter worker threads to be 1, but this will be tunable in the future once
we analyze the thread safety of each filter.

The output thread model one thread per output. Each output has its own queue
receiving events. This is implemented in logstash with LogStash::MultiQueue.

## Consequences and Expectations

Small queue sizes mean that logstash simply blocks and stalls safely during
times of load or other temporary pipeline problems. The alternative is
unlimited queues which grow unbounded and eventually exceed memory causing a
crash which loses all of those messages.

At a minum, logstash will have probably 3 threads (2 if you have no filters).
One input, one filter worker, and one output thread each.

If you see logstash using multiple CPUs, this is likely why. If you want to
know more about what each thread is doing, you should read this:
<http://www.semicomplete.com/blog/geekery/debugging-java-performance.html>.

Threads in java have names, and you can use jstack and top to figure out who is
using what resources. The URL above will help you learn how to do this.
