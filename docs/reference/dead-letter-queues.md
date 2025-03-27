---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/dead-letter-queues.html
---

# Dead letter queues (DLQ) [dead-letter-queues]

The dead letter queue (DLQ) is designed as a place to temporarily write events that cannot be processed. The DLQ gives you flexibility to investigate problematic events without blocking the pipeline or losing the events. Your pipeline keeps flowing, and the immediate problem is averted. But those events still need to be addressed.

You can [process events from the DLQ](#es-proc-dlq) with the [`dead_letter_queue` input plugin](logstash-docs-md://lsr/plugins-inputs-dead_letter_queue.md) .

Processing events does not delete items from the queue, and the DLQ sometimes needs attention. See [Track dead letter queue size](#dlq-size) and [Clear the dead letter queue](#dlq-clear) for more info.

## How the dead letter queue works [dead-letter-how]

By default, when Logstash encounters an event that it cannot process because the data contains a mapping error or some other issue, the Logstash pipeline either hangs or drops the unsuccessful event. In order to protect against data loss in this situation, you can [configure Logstash](#configuring-dlq) to write unsuccessful events to a dead letter queue instead of dropping them.

::::{note}
The dead letter queue is currently supported only for the [{{es}} output](logstash-docs-md://lsr/plugins-outputs-elasticsearch.md) and [conditional statements evaluation](/reference/event-dependent-configuration.md#conditionals). The dead letter queue is used for documents with response codes of 400 or 404, both of which indicate an event that cannot be retried. It’s also used when a conditional evaluation encounter an error.
::::


Each event written to the dead letter queue includes the original event, metadata that describes the reason the event could not be processed, information about the plugin that wrote the event, and the timestamp when the event entered the dead letter queue.

To process events in the dead letter queue, create a Logstash pipeline configuration that uses the [`dead_letter_queue` input plugin](logstash-docs-md://lsr/plugins-inputs-dead_letter_queue.md) to read from the queue. See [Processing events in the dead letter queue](#processing-dlq-events) for more information.

:::{image} images/dead_letter_queue.png
:alt: Diagram showing pipeline reading from the dead letter queue
:::


## {{es}} processing and the dead letter queue [es-proc-dlq]

**HTTP request failure.** If the HTTP request fails (because {{es}} is unreachable or because it returned an HTTP error code), the {{es}} output retries the entire request indefinitely. In these scenarios, the dead letter queue has no opportunity to intercept.

**HTTP request success.** The [{{es}} Bulk API](https://www.elastic.co/docs/api/doc/elasticsearch/operation/operation-bulk) can perform multiple actions using the same request. If the Bulk API request is successful, it returns `200 OK`, even if some documents in the batch have [failed](https://www.elastic.co/docs/api/doc/elasticsearch/operation/operation-bulk#bulk-failures-ex). In this situation, the `errors` flag for the request will be `true`.

The response body can include metadata indicating that one or more specific actions in the bulk request could not be performed, along with an HTTP-style status code per entry to indicate why the action could not be performed. If the DLQ is configured, individual indexing failures are routed there.

Even if you regularly process events, events remain in the dead letter queue. The dead letter queue requires [manual intervention](#dlq-clear) to clear it.


## Conditional statements and the dead letter queue [conditionals-dlq]

When a conditional statement reaches an error in processing an event, such as comparing string and integer values, the event, as it is at the time of evaluation, is inserted into the dead letter queue.


## Configuring {{ls}} to use dead letter queues [configuring-dlq]

Dead letter queues are disabled by default. To enable dead letter queues, set the `dead_letter_queue_enable` option in the `logstash.yml` [settings file](/reference/logstash-settings-file.md):

```yaml
dead_letter_queue.enable: true
```

Dead letter queues are stored as files in the local directory of the Logstash instance. By default, the dead letter queue files are stored in `path.data/dead_letter_queue`. Each pipeline has a separate queue. For example, the dead letter queue for the `main` pipeline is stored in `LOGSTASH_HOME/data/dead_letter_queue/main` by default. The queue files are numbered sequentially: `1.log`, `2.log`, and so on.

You can set `path.dead_letter_queue` in the `logstash.yml` file to specify a different path for the files:

```yaml
path.dead_letter_queue: "path/to/data/dead_letter_queue"
```

::::{tip}
Use the local filesystem for data integrity and performance. Network File System (NFS) is not supported.
::::


Dead letter queue entries are written to a temporary file, which is then renamed to a dead letter queue segment file, which is then eligible for ingestion. The rename happens either when this temporary file is considered *full*, or when a period of time has elapsed since the last dead letter queue eligible event was written to the temporary file.

This length of time can be set using the `dead_letter_queue.flush_interval` setting. This setting is in milliseconds, and defaults to 5000ms. A low value here will mean in the event of infrequent writes to the dead letter queue more, smaller, queue files may be written, while a larger value will introduce more latency between items being "written" to the dead letter queue, and being made available for reading by the dead_letter_queue input.

```
Note that this value cannot be set to lower than 1000ms.
```
```yaml
dead_letter_queue.flush_interval: 5000
```

::::{note}
You may not use the same `dead_letter_queue` path for two different Logstash instances.
::::


### File rotation [file-rotation]

Dead letter queues have a built-in file rotation policy that manages the file size of the queue. When the file size reaches a preconfigured threshold, a new file is created automatically.


### Size management [size-management]

By default, the maximum size of each dead letter queue is set to 1024mb. To change this setting, use the `dead_letter_queue.max_bytes` option.  Entries will be dropped if they would increase the size of the dead letter queue beyond this setting. Use the `dead_letter_queue.storage_policy` option to control which entries should be dropped to avoid exceeding the size limit. Set the value to `drop_newer` (default) to stop accepting new values that would push the file size over the limit. Set the value to `drop_older` to remove the oldest events to make space for new ones.

#### Age policy [age-policy]

You can use the age policy to automatically control the volume of events in the dead letter queue. Use the `dead_letter_queue.retain.age` setting (in `logstash.yml` or `pipelines.yml`) to have {{ls}} remove events that are older than a value you define. Available time units are `d`, `h`, `m`, `s` respectively for days, hours, minutes and seconds. There is no default time unit, so you need to specify it.

```yaml
dead_letter_queue.retain.age: 2d
```

The age policy is verified and applied on event writes and during pipeline shutdown. For that reason, your dead-letter-queue folder may store expired events for longer than specified, and the reader pipeline could possibly encounter outdated events.



### Automatic cleaning of consumed events [auto-clean]

By default, the dead letter queue input plugin does not remove the events that it consumes. Instead, it commits a reference to avoid re-processing events. Use the `clean_consumed` setting in the dead letter queue input plugin in order to remove segments that have been fully consumed, freeing space while processing.

```yaml
input {
  dead_letter_queue {
  	path => "/path/to/data/dead_letter_queue"
  	pipeline_id => "main"
    clean_consumed => true
  }
}
```



## Processing events in the dead letter queue [processing-dlq-events]

When you are ready to process events in the dead letter queue, you create a pipeline that uses the [`dead_letter_queue` input plugin](logstash-docs-md://lsr/plugins-inputs-dead_letter_queue.md) to read from the dead letter queue. The pipeline configuration that you use depends, of course, on what you need to do. For example, if the dead letter queue contains events that resulted from a mapping error in Elasticsearch, you can create a pipeline that reads the "dead" events, removes the field that caused the mapping issue, and re-indexes the clean events into Elasticsearch.

The following example shows a simple pipeline that reads events from the dead letter queue and writes the events, including metadata, to standard output:

```yaml
input {
  dead_letter_queue {
    path => "/path/to/data/dead_letter_queue" <1>
    commit_offsets => true <2>
    pipeline_id => "main" <3>
  }
}

output {
  stdout {
    codec => rubydebug { metadata => true }
  }
}
```

1. The path to the top-level directory containing the dead letter queue. This directory contains a separate folder for each pipeline that writes to the dead letter queue. To find the path to this directory, look at the `logstash.yml` [settings file](/reference/logstash-settings-file.md). By default, Logstash creates the `dead_letter_queue` directory under the location used for persistent storage (`path.data`), for example, `LOGSTASH_HOME/data/dead_letter_queue`. However, if `path.dead_letter_queue` is set, it uses that location instead.
2. When `true`, saves the offset. When the pipeline restarts, it will continue reading from the position where it left off rather than reprocessing all the items in the queue. You can set `commit_offsets` to `false` when you are exploring events in the dead letter queue and want to iterate over the events multiple times.
3. The ID of the pipeline that’s writing to the dead letter queue. The default is `"main"`.


For another example, see [Example: Processing data that has mapping errors](#dlq-example).

When the pipeline has finished processing all the events in the dead letter queue, it will continue to run and process new events as they stream into the queue. This means that you do not need to stop your production system to handle events in the dead letter queue.

::::{note}
Events emitted from the [`dead_letter_queue` input plugin](logstash-docs-md://lsr/plugins-inputs-dead_letter_queue.md) plugin will not be resubmitted to the dead letter queue if they cannot be processed correctly.
::::



## Reading from a timestamp [dlq-timestamp]

When you read from the dead letter queue, you might not want to process all the events in the queue, especially if there are a lot of old events in the queue. You can start processing events at a specific point in the queue by using the `start_timestamp` option. This option configures the pipeline to start processing events based on the timestamp of when they entered the queue:

```yaml
input {
  dead_letter_queue {
    path => "/path/to/data/dead_letter_queue"
    start_timestamp => "2017-06-06T23:40:37"
    pipeline_id => "main"
  }
}
```

For this example, the pipeline starts reading all events that were delivered to the dead letter queue on or after June 6, 2017, at 23:40:37.


## Example: Processing data that has mapping errors [dlq-example]

In this example, the user attempts to index a document that includes geo_ip data, but the data cannot be processed because it contains a mapping error:

```json
{"geoip":{"location":"home"}}
```

Indexing fails because the Logstash output plugin expects a `geo_point` object in the `location` field, but the value is a string. The failed event is written to the dead letter queue, along with metadata about the error that caused the failure:

```json
{
   "@metadata" => {
    "dead_letter_queue" => {
       "entry_time" => #<Java::OrgLogstash::Timestamp:0x5b5dacd5>,
        "plugin_id" => "fb80f1925088497215b8d037e622dec5819b503e-4",
      "plugin_type" => "elasticsearch",
           "reason" => "Could not index event to Elasticsearch. status: 400, action: [\"index\", {:_id=>nil, :_index=>\"logstash-2017.06.22\", :_type=>\"doc\", :_routing=>nil}, 2017-06-22T01:29:29.804Z My-MacBook-Pro-2.local {\"geoip\":{\"location\":\"home\"}}], response: {\"index\"=>{\"_index\"=>\"logstash-2017.06.22\", \"_type\"=>\"doc\", \"_id\"=>\"AVzNayPze1iR9yDdI2MD\", \"status\"=>400, \"error\"=>{\"type\"=>\"mapper_parsing_exception\", \"reason\"=>\"failed to parse\", \"caused_by\"=>{\"type\"=>\"illegal_argument_exception\", \"reason\"=>\"illegal latitude value [266.30859375] for geoip.location\"}}}}"
    }
  },
  "@timestamp" => 2017-06-22T01:29:29.804Z,
    "@version" => "1",
       "geoip" => {
    "location" => "home"
  },
        "host" => "My-MacBook-Pro-2.local",
     "message" => "{\"geoip\":{\"location\":\"home\"}}"
}
```

To process the failed event, you create the following pipeline that reads from the dead letter queue and removes the mapping problem:

```json
input {
  dead_letter_queue {
    path => "/path/to/data/dead_letter_queue/" <1>
  }
}
filter {
  mutate {
    remove_field => "[geoip][location]" <2>
  }
}
output {
  elasticsearch{
    hosts => [ "localhost:9200" ] <3>
  }
}
```

1. The [`dead_letter_queue` input](logstash-docs-md://lsr/plugins-inputs-dead_letter_queue.md) reads from the dead letter queue.
2. The `mutate` filter removes the problem field called `location`.
3. The clean event is sent to Elasticsearch, where it can be indexed because the mapping issue is resolved.



## Track dead letter queue size [dlq-size]

Monitor the size of the dead letter queue before it becomes a problem. By checking it periodically, you can determine the maximum queue size that makes sense for each pipeline.

The size of the DLQ for each pipeline is available in the node stats API.

```txt
pipelines.${pipeline_id}.dead_letter_queue.queue_size_in_bytes.
```

Where `{{pipeline_id}}` is the name of a pipeline with DLQ enabled.


## Clear the dead letter queue [dlq-clear]

The dead letter queue cannot be cleared with the upstream pipeline running.

The dead letter queue is a directory of pages. To clear it, stop the pipeline and delete location/<file-name>.

```txt
${path.data}/dead_letter_queue/${pipeline_id}
```

Where `{{pipeline_id}}` is the name of a pipeline with DLQ enabled.

The pipeline creates a new dead letter queue when it starts again.
