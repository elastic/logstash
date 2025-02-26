---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/processing.html
---

# Processing Details [processing]

Understanding how {{ls}} works and how components interrelate can help you make better decisions when you are setting up or adjusting your {{ls}} environment. This section is designed to elevate concepts to assist with that level of knowledge.

::::{note}
This is a new section. We’re still working on it.
::::



## Event ordering [event-ordering]

By design and by default, {{ls}} does not guarantee event order. Reordering can occur in two places:

* Events within a batch can be reordered during filter processing.
* In-flight batches can be reordered when one or more batches are processed faster than others.

When maintaining event order is important, use a single worker and set *pipeline.ordered ⇒ true*. This approach ensures that batches are computed one-after-the-other, and that events maintain their order within the batch.


### *pipeline.ordered* setting [order-setting]

The `pipeline.ordered` setting in [logstash.yml](/reference/logstash-settings-file.md) gives you more control over event ordering for single worker pipelines.

`auto` automatically enables ordering if the `pipeline.workers` setting is also set to `1`. `true` will enforce ordering on the pipeline and prevent logstash from starting if there are multiple workers. `false` will disable the processing required to preserve order. Ordering will not be guaranteed, but you save the processing cost required to preserve order.


## Java pipeline initialization time [pipeline-init-time]

The Java pipeline initialization time appears in the startup logs at INFO level. Initialization time is the time it takes to compile the pipeline config and instantiate the compiled execution for all workers.


## Reserved fields in {{ls}} events [reserved-fields]

Some fields in {{ls}} events are reserved, or are required to adhere to a certain shape. Using these fields can cause runtime exceptions when the event API or plugins encounter incompatible values.

|  |  |
| --- | --- |
| [`@metadata`](/reference/event-dependent-configuration.md#metadata) | A key/value map.<br>Ruby-based Plugin API: value is an[org.jruby.RubyHash](https://javadoc.io/static/org.jruby/jruby-core/9.2.5.0/org/jruby/RubyHash.md).<br>Java-based Plugin API: value is an[org.logstash.ConvertedMap](https://github.com/elastic/logstash/blob/main/logstash-core/src/main/java/org/logstash/ConvertedMap.java).<br>In serialized form (such as JSON): a key/value map where the keys must bestrings and the values are not constrained to a particular type. |
| `@timestamp` | An object holding representation of a specific moment in time.<br>Ruby-based Plugin API: value is an[org.jruby.RubyTime](https://javadoc.io/static/org.jruby/jruby-core/9.2.5.0/org/jruby/RubyTime.md).<br>Java-based Plugin API: value is a[java.time.Instant](https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/time/Instant.md).<br>In serialized form (such as JSON) or when setting with Event#set: anISO8601-compliant String value is acceptable. |
| `@version` | A string, holding an integer value. |
| `tags` | An array of distinct strings |

