---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/tips.html
---

# Tips and best practices [tips]

This section covers system configuration and best practices for running Logstash:

* [JVM settings](/reference/jvm-settings.md)
* [File descriptors](/reference/file-descriptors.md)

We are adding more tips and best practices, so please check back soon. If you have something to add, please:

* create an issue at [https://github.com/elastic/logstash/issues](https://github.com/elastic/logstash/issues), or
* create a pull request with your proposed changes at [https://github.com/elastic/logstash](https://github.com/elastic/logstash).

Also check out the [Logstash discussion forum](https://discuss.elastic.co/c/logstash).


## Command line [tip-cli]


### Shell commands on Windows OS [tip-windows-cli]

Command line examples often show single quotes. On Windows systems, replace a single quote `'` with a double quote `"`.

**Example**

Instead of:

```
bin/logstash -e 'input { stdin { } } output { stdout {} }'
```

Use this format on Windows systems:

```
bin\logstash -e "input { stdin { } } output { stdout {} }"
```


## Pipelines [tip-pipelines]


### Pipeline management [tip-pipeline-mgmt]

You can manage pipelines in a {{ls}} instance using either local pipeline configurations or [centralized pipeline management](/reference/configuring-centralized-pipelines.md) in {{kib}}.

After you configure Logstash to use centralized pipeline management, you can no longer specify local pipeline configurations. The `pipelines.yml` file and settings such as `path.config` and `config.string` are inactive when centralized pipeline management is enabled.


## Tips using filters [tip-filters]


### Check to see if a boolean field exists [tip-check-field]

You can use the mutate filter to see if a boolean field exists.

{{ls}} supports [@metadata] fields—​fields that are not visible for output plugins and live only in the filtering state. You can use [@metadata] fields with the mutate filter to see if a field exists.

```ruby
filter {
  mutate {
    # we use a "temporal" field with a predefined arbitrary known value that
    # lives only in filtering stage.
    add_field => { "[@metadata][test_field_check]" => "a null value" }
  }

filter {
  mutate {
    # we copy the field of interest into that temporal field.
    # If the field doesn't exist, copy is not executed.
    copy => { "test_field" => "[@metadata][test_field_check]" }
  }

  # now we now if testField didn't exists, our field will have
  # the initial arbitrary value
  if [@metadata][test_field_check] == "a null value" {
    # logic to execute when [test_field] did not exist
    mutate { add_field => { "field_did_not_exist" => true }}
  } else {
    # logic to execute when [test_field] existed
    mutate { add_field => { "field_did_exist" => true }}
  }
}
```


## Kafka [tip-kafka]


### Kafka settings [tip-kafka-settings]


#### Partitions per topic [tip-kafka-partitions]

"How many partitions should I use per topic?"

At least the number of {{ls}} nodes multiplied by consumer threads per node.

Better yet, use a multiple of the above number. Increasing the number of partitions for an existing topic is extremely complicated. Partitions have a very low overhead. Using 5 to 10 times the number of partitions suggested by the first point is generally fine, so long as the overall partition count does not exceed 2000.

Err on the side of over-partitioning up to a total 1000 partitions overall. Try not to exceed 1000 partitions.


#### Consumer threads [tip-kafka-threads]

"How many consumer threads should I configure?"

Lower values tend to be more efficient and have less memory overhead. Try a value of `1` then iterate your way up. The value should in general be lower than the number of pipeline workers. Values larger than 4 rarely result in performance improvement.


### Kafka input and persistent queue (PQ) [tip-kafka-pq-persist]


#### Kafka offset commits [tip-kafka-offset-commit]

"Does Kafka Input commit offsets only after the event has been safely persisted to the PQ?"

"Does Kafa Input commit offsets only for events that have passed the pipeline fully?"

No, we can’t make that guarantee. Offsets are committed to Kafka periodically. If writes to the PQ are slow or blocked, offsets for events that haven’t safely reached the PQ can be committed.


