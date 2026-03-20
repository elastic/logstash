---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/resiliency.html
---

# Queues and data resiliency [resiliency]

As data flows through the event processing pipeline, {{ls}} may encounter situations that prevent it from delivering events to the configured output. For example, the data might contain unexpected data types, or {{ls}} might terminate abnormally.

**Memory queue (MQ)**
:   By default, {{ls}} uses [in-memory bounded queues](/reference/memory-queue.md) between pipeline stages (inputs → pipeline workers) to buffer events.
Memory queues have [limitations](/reference/memory-queue.md#mem-queue-limitations), but also offer [benefits](/reference/memory-queue.md##mem-queue-benefits) that make them a good choice for many users. 
If memory queues don't offer the resiliency you need, {{ls}} provides more options. 

## {{ls}} data resiliency options [ls-queues]

To guard against data loss and ensure that events flow through the pipeline without interruption, {{ls}} provides additional data resiliency features.
These features are disabled by default. To turn on these features, you must explicitly enable them in the {{ls}} [settings file](/reference/logstash-settings-file.md).

**Persistent queues (PQ)**
:   [Persistent queues (PQ)](/reference/persistent-queues.md) protect against data loss by storing events in an internal queue on disk.

**Dead letter queues (DLQ)**
:   [Dead letter queues (DLQ)](/reference/dead-letter-queues.md) provide on-disk storage for events that {{ls}} is unable to process so that you can evaluate them. You can easily reprocess events in the dead letter queue by using the `dead_letter_queue` input plugin.

## {{es}} failure store [es-failure-store]
```{applies_to}
serverless: ga
stack: ga 9.1+
```

When you use {{ls}} to send data streams to {{es}}, you have an additional option for data resiliency--the {{es}} [failure store](docs-content://manage-data/data-store/data-streams/failure-store.md).
The {{es}} failure store for data streams offers {{ls}} users another alternative for handling events that can't be processed. 

A failure store is a secondary set of indices inside a data stream that is dedicated to storing failed documents. 
When a data stream's failure store is enabled, failures are captured in a separate index and persisted to be analyzed later. 
{{ls}} offers the Dead Letter Queue (DLQ), but the failure store is likely be a more practical option for most {{es}} users.

Check out [Failure store](docs-content://manage-data/data-store/data-streams/failure-store.md) for details.
