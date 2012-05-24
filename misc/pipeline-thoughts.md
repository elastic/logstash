## Terms

* input = source = emitter = sender
* filter = decorator = processor 
* output = destination = sink = consumer = receiver

In this pipeline model, I will call any input, filter, or output a 'station'

## Properties

* inputs produce messages
* filters modify or drop messages
* outputs consume messages

Filters have both producer and consumer properties.

## Pipeline stall strategies

Which has the buffer? The input or the output?

* In TCP, the sender stalls if the receiver stops acking.
* In a Ruby SizedQueue, the sender stalls (SizedQueue#push) if receiver stops popping.

In both cases above, inaction by the receiver causes the sender to stall. This is nice because throttling requires no negotiation. 

Further, stall behavior can be modified simply by writing a filter that changes its behavior when a stall is detected. For example, instead of blocking the pipeline, a stall-managing filter could choose to drop messages so as to unblock upstream stations.

## Parallelization strategies

* Every station can run a tunable number of workers.
  * Input rationale: For slow consumers like bunny/amqp, logstash users have observed that 4 amqp inputs work faster than 1 amqp input, even with prefetch >100
  * Filter rationale: CPU-intensive filters like parsers benefit from parallelization
  * Output rationale: Same for inputs. Slow-in-code outputs can often mitigated simply by running more of those slow things.
* A worker is one process/thread.

Currently logstash implements all filters in a single worker thread. This causes order problems when using the multiline filter. If instead each filter could have a tunable number of workers, we could leave multline at 1 worker and use 10 for grok and date processing.

## Maintaining Order

When introducing parallelism, the order of messages will be lost without care. This can matter in cases like with logstash's multline filter. In general, this may not be an issue.

## Station plumbing

In this scenario, station plumbing is considered only for in-process communication. External plumbing is trivially achieved by implementing networked inputs and outputs.

* Is Ruby's SizedQueue fast enough? How do MRI and JRuby's SizedQueue implementation performances vary?
* File descriptors require syscalls to ship messages, probably not good at high performance.

## Station data model

* worker count
* metrics

## Pipeline data model

* ordered list of stations
