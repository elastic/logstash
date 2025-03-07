---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/resiliency.html
---

# Queues and data resiliency [resiliency]

By default, Logstash uses [in-memory bounded queues](/reference/memory-queue.md) between pipeline stages (inputs → pipeline workers) to buffer events.

As data flows through the event processing pipeline, Logstash may encounter situations that prevent it from delivering events to the configured output. For example, the data might contain unexpected data types, or Logstash might terminate abnormally.

To guard against data loss and ensure that events flow through the pipeline without interruption, Logstash provides data resiliency features.

* [Persistent queues (PQ)](/reference/persistent-queues.md) protect against data loss by storing events in an internal queue on disk.
* [Dead letter queues (DLQ)](/reference/dead-letter-queues.md) provide on-disk storage for events that Logstash is unable to process so that you can evaluate them. You can easily reprocess events in the dead letter queue by using the `dead_letter_queue` input plugin.

These resiliency features are disabled by default. To turn on these features, you must explicitly enable them in the Logstash [settings file](/reference/logstash-settings-file.md).




