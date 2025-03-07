---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/execution-model.html
---

# Execution Model [execution-model]

The Logstash event processing pipeline coordinates the execution of inputs, filters, and outputs.

Each input stage in the Logstash pipeline runs in its own thread. Inputs write events to a central queue that is either in memory (default) or on disk. Each pipeline worker thread takes a batch of events off this queue, runs the batch of events through the configured filters, and then runs the filtered events through any outputs. The size of the batch and number of pipeline worker threads are configurable (see [Tuning and profiling logstash pipeline performance](/reference/tuning-logstash.md)).

By default, Logstash uses in-memory bounded queues between pipeline stages (input → filter and filter → output) to buffer events. If Logstash terminates unsafely, any events that are stored in memory will be lost. To help prevent data loss, you can enable Logstash to persist in-flight events to disk. See [Persistent queues (PQ)](/reference/persistent-queues.md) for more information.

