---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/memory-queue.html
---

# Memory queue [memory-queue]

By default, Logstash uses in-memory bounded queues between pipeline stages (inputs → pipeline workers) to buffer events. If Logstash experiences a temporary machine failure, the contents of the memory queue will be lost. Temporary machine failures are scenarios where Logstash or its host machine are terminated abnormally, but are capable of being restarted.

## Benefits of memory queues [mem-queue-benefits]

The memory queue might be a good choice if you value throughput over data resiliency.

* Easier configuration
* Easier management and administration
* Faster throughput


## Limitations of memory queues [mem-queue-limitations]

* Can lose data in abnormal termination
* Don’t do well handling sudden bursts of data, where extra capacity in needed for {{ls}} to catch up

::::{tip}
Consider using [persistent queues](/reference/persistent-queues.md) to avoid these limitations.
::::



## Memory queue size [sizing-mem-queue]

Memory queue size is not configured directly. Instead, it depends on how you have Logstash tuned.

Its upper bound is defined by `pipeline.workers` (default: number of CPUs) times the `pipeline.batch.size` (default: 125) events. This value, called the "inflight count," determines maximum number of events that can be held in each memory queue.

Doubling the number of workers OR doubling the batch size will effectively double the memory queue’s capacity (and memory usage). Doubling both will *quadruple* the capacity (and usage).

::::{important}
Each pipeline has its own queue.
::::


See [Tuning and profiling logstash pipeline performance](/reference/tuning-logstash.md) for more info on the effects of adjusting `pipeline.batch.size` and `pipeline.workers`.

If you need to absorb bursts of traffic, consider using [persistent queues](/reference/persistent-queues.md) instead. Persistent queues are bound to allocated capacity on disk.

### Settings that affect queue size [mq-settings]

These values can be configured in `logstash.yml` and `pipelines.yml`.

pipeline.batch.size
:   Number events to retrieve from inputs before sending to filters+workers The default is 125.

pipelines.workers
:   Number of workers that will, in parallel, execute the filters+outputs stage of the pipeline. This value defaults to the number of the host’s CPU cores.



## Back pressure [backpressure-mem-queue]

When the queue is full, Logstash puts back pressure on the inputs to stall data flowing into Logstash. This mechanism helps Logstash control the rate of data flow at the input stage without overwhelming outputs like Elasticsearch.

Each input handles back pressure independently.


