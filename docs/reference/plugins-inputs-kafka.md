---
navigation_title: "kafka"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-inputs-kafka.html
---

# Kafka input plugin [plugins-inputs-kafka]


* A component of the [kafka integration plugin](/reference/plugins-integrations-kafka.md)
* Integration version: v11.6.0
* Released on: 2025-01-07
* [Changelog](https://github.com/logstash-plugins/logstash-integration-kafka/blob/v11.6.0/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://reference/input-kafka-index.md).

## Getting help [_getting_help_35]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-integration-kafka). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_35]

This input will read events from a Kafka topic.

This plugin uses Kafka Client 3.8.1. For broker compatibility, see the official [Kafka compatibility reference](https://cwiki.apache.org/confluence/display/KAFKA/Compatibility+Matrix). If the linked compatibility wiki is not up-to-date, please contact Kafka support/community to confirm compatibility.

If you require features not yet available in this plugin (including client version upgrades), please file an issue with details about what you need.

This input supports connecting to Kafka over:

* SSL (requires plugin version 3.0.0 or later)
* Kerberos SASL (requires plugin version 5.1.0 or later)

By default security is disabled but can be turned on as needed.

::::{note}
This plugin does not support using a proxy when communicating to the Kafka broker.

This plugin does support using a proxy when communicating to the Schema Registry using the [`schema_registry_proxy`](#plugins-inputs-kafka-schema_registry_proxy) option.

::::


The Logstash Kafka consumer handles group management and uses the default offset management strategy using Kafka topics.

Logstash instances by default form a single logical group to subscribe to Kafka topics Each Logstash Kafka consumer can run multiple threads to increase read throughput. Alternatively, you could run multiple Logstash instances with the same `group_id` to spread the load across physical machines. Messages in a topic will be distributed to all Logstash instances with the same `group_id`.

Ideally you should have as many threads as the number of partitions for a perfect balance — more threads than partitions means that some threads will be idle

For more information see [https://kafka.apache.org/38/documentation.html#theconsumer](https://kafka.apache.org/38/documentation.md#theconsumer)

Kafka consumer configuration: [https://kafka.apache.org/38/documentation.html#consumerconfigs](https://kafka.apache.org/38/documentation.md#consumerconfigs)


## Metadata fields [_metadata_fields]

The following metadata from Kafka broker are added under the `[@metadata]` field:

* `[@metadata][kafka][topic]`: Original Kafka topic from where the message was consumed.
* `[@metadata][kafka][consumer_group]`: Consumer group
* `[@metadata][kafka][partition]`: Partition info for this message.
* `[@metadata][kafka][offset]`: Original record offset for this message.
* `[@metadata][kafka][key]`: Record key, if any.
* `[@metadata][kafka][timestamp]`: Timestamp in the Record. Depending on your broker configuration, this can be either when the record was created (default) or when it was received by the broker. See more about property log.message.timestamp.type at [https://kafka.apache.org/38/documentation.html#brokerconfigs](https://kafka.apache.org/38/documentation.md#brokerconfigs)

Metadata is only added to the event if the `decorate_events` option is set to `basic` or `extended` (it defaults to `none`).

Please note that `@metadata` fields are not part of any of your events at output time. If you need these information to be inserted into your original event, you’ll have to use the `mutate` filter to manually copy the required fields into your `event`.


## Kafka Input Configuration Options [plugins-inputs-kafka-options]

This plugin supports these configuration options plus the [Common options](#plugins-inputs-kafka-common-options) described later.

::::{note}
Some of these options map to a Kafka option. Defaults usually reflect the Kafka default setting, and might change if Kafka’s consumer defaults change. See the [https://kafka.apache.org/38/documentation](https://kafka.apache.org/38/documentation) for more details.
::::


| Setting | Input type | Required |
| --- | --- | --- |
| [`auto_commit_interval_ms`](#plugins-inputs-kafka-auto_commit_interval_ms) | [number](/reference/configuration-file-structure.md#number) | No |
| [`auto_create_topics` ](#plugins-inputs-kafka-auto_create_topics) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`auto_offset_reset`](#plugins-inputs-kafka-auto_offset_reset) | [string](/reference/configuration-file-structure.md#string) | No |
| [`bootstrap_servers`](#plugins-inputs-kafka-bootstrap_servers) | [string](/reference/configuration-file-structure.md#string) | No |
| [`check_crcs`](#plugins-inputs-kafka-check_crcs) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`client_dns_lookup`](#plugins-inputs-kafka-client_dns_lookup) | [string](/reference/configuration-file-structure.md#string) | No |
| [`client_id`](#plugins-inputs-kafka-client_id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`client_rack`](#plugins-inputs-kafka-client_rack) | [string](/reference/configuration-file-structure.md#string) | No |
| [`connections_max_idle_ms`](#plugins-inputs-kafka-connections_max_idle_ms) | [number](/reference/configuration-file-structure.md#number) | No |
| [`consumer_threads`](#plugins-inputs-kafka-consumer_threads) | [number](/reference/configuration-file-structure.md#number) | No |
| [`decorate_events`](#plugins-inputs-kafka-decorate_events) | [string](/reference/configuration-file-structure.md#string) | No |
| [`enable_auto_commit`](#plugins-inputs-kafka-enable_auto_commit) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`exclude_internal_topics`](#plugins-inputs-kafka-exclude_internal_topics) | [string](/reference/configuration-file-structure.md#string) | No |
| [`fetch_max_bytes`](#plugins-inputs-kafka-fetch_max_bytes) | [number](/reference/configuration-file-structure.md#number) | No |
| [`fetch_max_wait_ms`](#plugins-inputs-kafka-fetch_max_wait_ms) | [number](/reference/configuration-file-structure.md#number) | No |
| [`fetch_min_bytes`](#plugins-inputs-kafka-fetch_min_bytes) | [number](/reference/configuration-file-structure.md#number) | No |
| [`group_id`](#plugins-inputs-kafka-group_id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`group_instance_id`](#plugins-inputs-kafka-group_instance_id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`heartbeat_interval_ms`](#plugins-inputs-kafka-heartbeat_interval_ms) | [number](/reference/configuration-file-structure.md#number) | No |
| [`isolation_level`](#plugins-inputs-kafka-isolation_level) | [string](/reference/configuration-file-structure.md#string) | No |
| [`jaas_path`](#plugins-inputs-kafka-jaas_path) | a valid filesystem path | No |
| [`kerberos_config`](#plugins-inputs-kafka-kerberos_config) | a valid filesystem path | No |
| [`key_deserializer_class`](#plugins-inputs-kafka-key_deserializer_class) | [string](/reference/configuration-file-structure.md#string) | No |
| [`max_partition_fetch_bytes`](#plugins-inputs-kafka-max_partition_fetch_bytes) | [number](/reference/configuration-file-structure.md#number) | No |
| [`max_poll_interval_ms`](#plugins-inputs-kafka-max_poll_interval_ms) | [number](/reference/configuration-file-structure.md#number) | No |
| [`max_poll_records`](#plugins-inputs-kafka-max_poll_records) | [number](/reference/configuration-file-structure.md#number) | No |
| [`metadata_max_age_ms`](#plugins-inputs-kafka-metadata_max_age_ms) | [number](/reference/configuration-file-structure.md#number) | No |
| [`partition_assignment_strategy`](#plugins-inputs-kafka-partition_assignment_strategy) | [string](/reference/configuration-file-structure.md#string) | No |
| [`poll_timeout_ms`](#plugins-inputs-kafka-poll_timeout_ms) | [number](/reference/configuration-file-structure.md#number) | No |
| [`receive_buffer_bytes`](#plugins-inputs-kafka-receive_buffer_bytes) | [number](/reference/configuration-file-structure.md#number) | No |
| [`reconnect_backoff_ms`](#plugins-inputs-kafka-reconnect_backoff_ms) | [number](/reference/configuration-file-structure.md#number) | No |
| [`request_timeout_ms`](#plugins-inputs-kafka-request_timeout_ms) | [number](/reference/configuration-file-structure.md#number) | No |
| [`retry_backoff_ms`](#plugins-inputs-kafka-retry_backoff_ms) | [number](/reference/configuration-file-structure.md#number) | No |
| [`sasl_client_callback_handler_class`](#plugins-inputs-kafka-sasl_client_callback_handler_class) | [string](/reference/configuration-file-structure.md#string) | No |
| [`sasl_oauthbearer_token_endpoint_url`](#plugins-inputs-kafka-sasl_oauthbearer_token_endpoint_url) | [string](/reference/configuration-file-structure.md#string) | No |
| [`sasl_oauthbearer_scope_claim_name`](#plugins-inputs-kafka-sasl_oauthbearer_scope_claim_name) | [string](/reference/configuration-file-structure.md#string) | No |
| [`sasl_login_callback_handler_class`](#plugins-inputs-kafka-sasl_login_callback_handler_class) | [string](/reference/configuration-file-structure.md#string) | No |
| [`sasl_login_connect_timeout_ms`](#plugins-inputs-kafka-sasl_login_connect_timeout_ms) | [number](/reference/configuration-file-structure.md#number) | No |
| [`sasl_login_read_timeout_ms`](#plugins-inputs-kafka-sasl_login_read_timeout_ms) | [number](/reference/configuration-file-structure.md#number) | No |
| [`sasl_login_retry_backoff_ms`](#plugins-inputs-kafka-sasl_login_retry_backoff_ms) | [number](/reference/configuration-file-structure.md#number) | No |
| [`sasl_login_retry_backoff_max_ms`](#plugins-inputs-kafka-sasl_login_retry_backoff_max_ms) | [number](/reference/configuration-file-structure.md#number) | No |
| [`sasl_jaas_config`](#plugins-inputs-kafka-sasl_jaas_config) | [string](/reference/configuration-file-structure.md#string) | No |
| [`sasl_kerberos_service_name`](#plugins-inputs-kafka-sasl_kerberos_service_name) | [string](/reference/configuration-file-structure.md#string) | No |
| [`sasl_mechanism`](#plugins-inputs-kafka-sasl_mechanism) | [string](/reference/configuration-file-structure.md#string) | No |
| [`schema_registry_key`](#plugins-inputs-kafka-schema_registry_key) | [string](/reference/configuration-file-structure.md#string) | No |
| [`schema_registry_proxy`](#plugins-inputs-kafka-schema_registry_proxy) | [uri](/reference/configuration-file-structure.md#uri) | No |
| [`schema_registry_secret`](#plugins-inputs-kafka-schema_registry_secret) | [string](/reference/configuration-file-structure.md#string) | No |
| [`schema_registry_ssl_keystore_location`](#plugins-inputs-kafka-schema_registry_ssl_keystore_location) | a valid filesystem path | No |
| [`schema_registry_ssl_keystore_password`](#plugins-inputs-kafka-schema_registry_ssl_keystore_password) | [password](/reference/configuration-file-structure.md#password) | No |
| [`schema_registry_ssl_keystore_type`](#plugins-inputs-kafka-schema_registry_ssl_keystore_type) | [string](/reference/configuration-file-structure.md#string), one of `["jks", "PKCS12"]` | No |
| [`schema_registry_ssl_truststore_location`](#plugins-inputs-kafka-schema_registry_ssl_truststore_location) | a valid filesystem path | No |
| [`schema_registry_ssl_truststore_password`](#plugins-inputs-kafka-schema_registry_ssl_truststore_password) | [password](/reference/configuration-file-structure.md#password) | No |
| [`schema_registry_ssl_truststore_type`](#plugins-inputs-kafka-schema_registry_ssl_truststore_type) | [string](/reference/configuration-file-structure.md#string), one of `["jks", "PKCS12"]` | No |
| [`schema_registry_url`](#plugins-inputs-kafka-schema_registry_url) | [uri](/reference/configuration-file-structure.md#uri) | No |
| [`schema_registry_validation`](#plugins-inputs-kafka-schema_registry_validation) | [string](/reference/configuration-file-structure.md#string) | No |
| [`security_protocol`](#plugins-inputs-kafka-security_protocol) | [string](/reference/configuration-file-structure.md#string), one of `["PLAINTEXT", "SSL", "SASL_PLAINTEXT", "SASL_SSL"]` | No |
| [`send_buffer_bytes`](#plugins-inputs-kafka-send_buffer_bytes) | [number](/reference/configuration-file-structure.md#number) | No |
| [`session_timeout_ms`](#plugins-inputs-kafka-session_timeout_ms) | [number](/reference/configuration-file-structure.md#number) | No |
| [`ssl_endpoint_identification_algorithm`](#plugins-inputs-kafka-ssl_endpoint_identification_algorithm) | [string](/reference/configuration-file-structure.md#string) | No |
| [`ssl_key_password`](#plugins-inputs-kafka-ssl_key_password) | [password](/reference/configuration-file-structure.md#password) | No |
| [`ssl_keystore_location`](#plugins-inputs-kafka-ssl_keystore_location) | a valid filesystem path | No |
| [`ssl_keystore_password`](#plugins-inputs-kafka-ssl_keystore_password) | [password](/reference/configuration-file-structure.md#password) | No |
| [`ssl_keystore_type`](#plugins-inputs-kafka-ssl_keystore_type) | [string](/reference/configuration-file-structure.md#string), one of `["jks", "PKCS12"]` | No |
| [`ssl_truststore_location`](#plugins-inputs-kafka-ssl_truststore_location) | a valid filesystem path | No |
| [`ssl_truststore_password`](#plugins-inputs-kafka-ssl_truststore_password) | [password](/reference/configuration-file-structure.md#password) | No |
| [`ssl_truststore_type`](#plugins-inputs-kafka-ssl_truststore_type) | [string](/reference/configuration-file-structure.md#string), one of `["jks", "PKCS12"]` | No |
| [`topics`](#plugins-inputs-kafka-topics) | [array](/reference/configuration-file-structure.md#array) | No |
| [`topics_pattern`](#plugins-inputs-kafka-topics_pattern) | [string](/reference/configuration-file-structure.md#string) | No |
| [`value_deserializer_class`](#plugins-inputs-kafka-value_deserializer_class) | [string](/reference/configuration-file-structure.md#string) | No |

Also see [Common options](#plugins-inputs-kafka-common-options) for a list of options supported by all input plugins.

 

### `auto_commit_interval_ms` [plugins-inputs-kafka-auto_commit_interval_ms]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `5000`.

The frequency in milliseconds that the consumer offsets are committed to Kafka.


### `auto_offset_reset` [plugins-inputs-kafka-auto_offset_reset]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

What to do when there is no initial offset in Kafka or if an offset is out of range:

* earliest: automatically reset the offset to the earliest offset
* latest: automatically reset the offset to the latest offset
* none: throw exception to the consumer if no previous offset is found for the consumer’s group
* anything else: throw exception to the consumer.


### `bootstrap_servers` [plugins-inputs-kafka-bootstrap_servers]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"localhost:9092"`

A list of URLs of Kafka instances to use for establishing the initial connection to the cluster. This list should be in the form of `host1:port1,host2:port2` These urls are just used for the initial connection to discover the full cluster membership (which may change dynamically) so this list need not contain the full set of servers (you may want more than one, though, in case a server is down).


### `check_crcs` [plugins-inputs-kafka-check_crcs]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Automatically check the CRC32 of the records consumed. This ensures no on-the-wire or on-disk corruption to the messages occurred. This check adds some overhead, so it may be disabled in cases seeking extreme performance.


### `client_dns_lookup` [plugins-inputs-kafka-client_dns_lookup]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"default"`

How DNS lookups should be done. If set to `use_all_dns_ips`, when the lookup returns multiple IP addresses for a hostname, they will all be attempted to connect to before failing the connection. If the value is `resolve_canonical_bootstrap_servers_only` each entry will be resolved and expanded into a list of canonical names.

::::{note}
Starting from Kafka 3 `default` value for `client.dns.lookup` value has been removed. If explicitly configured it fallbacks to `use_all_dns_ips`.

::::



### `client_id` [plugins-inputs-kafka-client_id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"logstash"`

The id string to pass to the server when making requests. The purpose of this is to be able to track the source of requests beyond just ip/port by allowing a logical application name to be included.


### `client_rack` [plugins-inputs-kafka-client_rack]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

A rack identifier for the Kafka consumer. Used to select the physically closest rack for the consumer to read from. The setting corresponds with Kafka’s `broker.rack` configuration.

::::{note}
Available only for Kafka 2.4.0 and higher. See [KIP-392](https://cwiki.apache.org/confluence/display/KAFKA/KIP-392%3A+Allow+consumers+to+fetch+from+closest+replica).
::::



### `connections_max_idle_ms` [plugins-inputs-kafka-connections_max_idle_ms]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `540000` milliseconds (9 minutes).

Close idle connections after the number of milliseconds specified by this config.


### `consumer_threads` [plugins-inputs-kafka-consumer_threads]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `1`

Ideally you should have as many threads as the number of partitions for a perfect balance — more threads than partitions means that some threads will be idle


### `decorate_events` [plugins-inputs-kafka-decorate_events]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Accepted values are:

    * `none`: no metadata is added
    * `basic`: record’s attributes are added
    * `extended`: record’s attributes, headers are added (limited to headers with values using UTF-8 encoding)
    * `false`: deprecated alias for `none`
    * `true`: deprecated alias for `basic`

* Default value is `none`

Option to add Kafka metadata like topic, message size and header key values to the event. This will add a field named `kafka` to the logstash event containing the following attributes:

* `topic`: The topic this message is associated with
* `consumer_group`: The consumer group used to read in this event
* `partition`: The partition this message is associated with
* `offset`: The offset from the partition this message is associated with
* `key`: A ByteBuffer containing the message key


### `auto_create_topics`  [plugins-inputs-kafka-auto_create_topics]

  * Value type is [boolean](/reference/configuration-file-structure.md#boolean) * Default value is `true`

Controls whether the topic is automatically created when subscribing to a non-existent topic. A topic will be auto-created only if this configuration is set to `true` and auto-topic creation is enabled on the broker using `auto.create.topics.enable`; otherwise auto-topic creation is not permitted. 


### `enable_auto_commit` [plugins-inputs-kafka-enable_auto_commit]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

This committed offset will be used when the process fails as the position from which the consumption will begin.

If true, periodically commit to Kafka the offsets of messages already returned by the consumer. If value is `false` however, the offset is committed every time the consumer writes data fetched from the topic to the in-memory or persistent queue.


### `exclude_internal_topics` [plugins-inputs-kafka-exclude_internal_topics]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Whether records from internal topics (such as offsets) should be exposed to the consumer. If set to true the only way to receive records from an internal topic is subscribing to it.


### `fetch_max_bytes` [plugins-inputs-kafka-fetch_max_bytes]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `52428800` (50MB)

The maximum amount of data the server should return for a fetch request. This is not an absolute maximum, if the first message in the first non-empty partition of the fetch is larger than this value, the message will still be returned to ensure that the consumer can make progress.


### `fetch_max_wait_ms` [plugins-inputs-kafka-fetch_max_wait_ms]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `500` milliseconds.

The maximum amount of time the server will block before answering the fetch request if there isn’t sufficient data to immediately satisfy `fetch_min_bytes`. This should be less than or equal to the timeout used in `poll_timeout_ms`


### `fetch_min_bytes` [plugins-inputs-kafka-fetch_min_bytes]

* Value type is [number](/reference/configuration-file-structure.md#number)
* There is no default value for this setting.

The minimum amount of data the server should return for a fetch request. If insufficient data is available the request will wait for that much data to accumulate before answering the request.


### `group_id` [plugins-inputs-kafka-group_id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"logstash"`

The identifier of the group this consumer belongs to. Consumer group is a single logical subscriber that happens to be made up of multiple processors. Messages in a topic will be distributed to all Logstash instances with the same `group_id`.

::::{note}
In cases when multiple inputs are being used in a single pipeline, reading from different topics, it’s essential to set a different `group_id => ...` for each input. Setting a unique `client_id => ...` is also recommended.
::::



### `group_instance_id` [plugins-inputs-kafka-group_instance_id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The static membership identifier for this Logstash Kafka consumer. Static membership feature was introduced in [KIP-345](https://cwiki.apache.org/confluence/display/KAFKA/KIP-345%3A+Introduce+static+membership+protocol+to+reduce+consumer+rebalances), available under Kafka property `group.instance.id`. Its purpose is to avoid rebalances in situations in which a lot of data has to be forwarded after a consumer goes offline. This feature mitigates cases where the service state is heavy and the rebalance of one topic partition from instance A to B would cause a huge amount of data to be transferred. A client that goes offline/online frequently can avoid frequent and heavy rebalances by using this option.

::::{note}
The `group_instance_id` setting must be unique across all the clients belonging to the same [`group_id`](#plugins-inputs-kafka-group_id). Otherwise, another client connecting with same `group.instance.id` value would cause the oldest instance to be disconnected. You can set this value to use information such as a hostname, an IP, or anything that uniquely identifies the client application.
::::


::::{note}
In cases when multiple threads are configured and `consumer_threads` is greater than one, a suffix is appended to the `group_instance_id` to avoid collisions.
::::



### `heartbeat_interval_ms` [plugins-inputs-kafka-heartbeat_interval_ms]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `3000` milliseconds (3 seconds).

The expected time between heartbeats to the consumer coordinator. Heartbeats are used to ensure that the consumer’s session stays active and to facilitate rebalancing when new consumers join or leave the group. The value must be set lower than `session.timeout.ms`, but typically should be set no higher than 1/3 of that value. It can be adjusted even lower to control the expected time for normal rebalances.


### `isolation_level` [plugins-inputs-kafka-isolation_level]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"read_uncommitted"`

Controls how to read messages written transactionally. If set to `read_committed`, polling messages will only return transactional messages which have been committed. If set to `read_uncommitted` (the default), polling messages will return all messages, even transactional messages which have been aborted. Non-transactional messages will be returned unconditionally in either mode.


### `jaas_path` [plugins-inputs-kafka-jaas_path]

* Value type is [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting.

The Java Authentication and Authorization Service (JAAS) API supplies user authentication and authorization services for Kafka. This setting provides the path to the JAAS file. Sample JAAS file for Kafka client:

```java
KafkaClient {
  com.sun.security.auth.module.Krb5LoginModule required
  useTicketCache=true
  renewTicket=true
  serviceName="kafka";
  };
```

Please note that specifying `jaas_path` and `kerberos_config` in the config file will add these to the global JVM system properties. This means if you have multiple Kafka inputs, all of them would be sharing the same `jaas_path` and `kerberos_config`. If this is not desirable, you would have to run separate instances of Logstash on different JVM instances.


### `kerberos_config` [plugins-inputs-kafka-kerberos_config]

* Value type is [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting.

Optional path to kerberos config file. This is krb5.conf style as detailed in [https://web.mit.edu/kerberos/krb5-1.12/doc/admin/conf_files/krb5_conf.html](https://web.mit.edu/kerberos/krb5-1.12/doc/admin/conf_files/krb5_conf.md)


### `key_deserializer_class` [plugins-inputs-kafka-key_deserializer_class]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"org.apache.kafka.common.serialization.StringDeserializer"`

Java Class used to deserialize the record’s key


### `max_partition_fetch_bytes` [plugins-inputs-kafka-max_partition_fetch_bytes]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `1048576` (1MB).

The maximum amount of data per-partition the server will return. The maximum total memory used for a request will be `#partitions * max.partition.fetch.bytes`. This size must be at least as large as the maximum message size the server allows or else it is possible for the producer to send messages larger than the consumer can fetch. If that happens, the consumer can get stuck trying to fetch a large message on a certain partition.


### `max_poll_interval_ms` [plugins-inputs-kafka-max_poll_interval_ms]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `300000` milliseconds (5 minutes).

The maximum delay between invocations of poll() when using consumer group management. This places an upper bound on the amount of time that the consumer can be idle before fetching more records. If poll() is not called before expiration of this timeout, then the consumer is considered failed and the group will rebalance in order to reassign the partitions to another member.


### `max_poll_records` [plugins-inputs-kafka-max_poll_records]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `500`.

The maximum number of records returned in a single call to poll().


### `metadata_max_age_ms` [plugins-inputs-kafka-metadata_max_age_ms]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `300000` milliseconds (5 minutes).

The period of time in milliseconds after which we force a refresh of metadata even if we haven’t seen any partition leadership changes to proactively discover any new brokers or partitions


### `partition_assignment_strategy` [plugins-inputs-kafka-partition_assignment_strategy]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The name of the partition assignment strategy that the client uses to distribute partition ownership amongst consumer instances, supported options are:

* `range`
* `round_robin`
* `sticky`
* `cooperative_sticky`

These map to Kafka’s corresponding [`ConsumerPartitionAssignor`](https://kafka.apache.org/38/javadoc/org/apache/kafka/clients/consumer/ConsumerPartitionAssignor.md) implementations.


### `poll_timeout_ms` [plugins-inputs-kafka-poll_timeout_ms]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `100` milliseconds.

Time Kafka consumer will wait to receive new messages from topics.

After subscribing to a set of topics, the Kafka consumer automatically joins the group when polling. The plugin poll-ing in a loop ensures consumer liveness. Underneath the covers, Kafka client sends periodic heartbeats to the server. The timeout specified the time to block waiting for input on each poll.


### `receive_buffer_bytes` [plugins-inputs-kafka-receive_buffer_bytes]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `32768` (32KB).

The size of the TCP receive buffer (SO_RCVBUF) to use when reading data.


### `reconnect_backoff_ms` [plugins-inputs-kafka-reconnect_backoff_ms]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `50` milliseconds.

The amount of time to wait before attempting to reconnect to a given host. This avoids repeatedly connecting to a host in a tight loop. This backoff applies to all requests sent by the consumer to the broker.


### `request_timeout_ms` [plugins-inputs-kafka-request_timeout_ms]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `40000` milliseconds (40 seconds).

The configuration controls the maximum amount of time the client will wait for the response of a request. If the response is not received before the timeout elapses the client will resend the request if necessary or fail the request if retries are exhausted.


### `retry_backoff_ms` [plugins-inputs-kafka-retry_backoff_ms]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `100` milliseconds.

The amount of time to wait before attempting to retry a failed fetch request to a given topic partition. This avoids repeated fetching-and-failing in a tight loop.


### `sasl_client_callback_handler_class` [plugins-inputs-kafka-sasl_client_callback_handler_class]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The SASL client callback handler class the specified SASL mechanism should use.


### `sasl_oauthbearer_token_endpoint_url` [plugins-inputs-kafka-sasl_oauthbearer_token_endpoint_url]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The URL for the OAuth 2.0 issuer token endpoint.


### `sasl_oauthbearer_scope_claim_name` [plugins-inputs-kafka-sasl_oauthbearer_scope_claim_name]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"scope"`

(optional) The override name of the scope claim.


### `sasl_login_callback_handler_class` [plugins-inputs-kafka-sasl_login_callback_handler_class]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The SASL login callback handler class the specified SASL mechanism should use.


### `sasl_login_connect_timeout_ms` [plugins-inputs-kafka-sasl_login_connect_timeout_ms]

* Value type is [number](/reference/configuration-file-structure.md#number)
* There is no default value for this setting.

(optional) The duration, in milliseconds, for HTTPS connect timeout


### `sasl_login_read_timeout_ms` [plugins-inputs-kafka-sasl_login_read_timeout_ms]

* Value type is [number](/reference/configuration-file-structure.md#number)
* There is no default value for this setting.

(optional) The duration, in milliseconds, for HTTPS read timeout.


### `sasl_login_retry_backoff_ms` [plugins-inputs-kafka-sasl_login_retry_backoff_ms]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `100` milliseconds.

(optional) The duration, in milliseconds, to wait between HTTPS call attempts.


### `sasl_login_retry_backoff_max_ms` [plugins-inputs-kafka-sasl_login_retry_backoff_max_ms]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `10000` milliseconds.

(optional) The maximum duration, in milliseconds, for HTTPS call attempts.


### `sasl_jaas_config` [plugins-inputs-kafka-sasl_jaas_config]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

JAAS configuration setting local to this plugin instance, as opposed to settings using config file configured using `jaas_path`, which are shared across the JVM. This allows each plugin instance to have its own configuration.

If both `sasl_jaas_config` and `jaas_path` configurations are set, the setting here takes precedence.

Example (setting for Azure Event Hub):

```ruby
    input {
      kafka {
        sasl_jaas_config => "org.apache.kafka.common.security.plain.PlainLoginModule required username='auser'  password='apassword';"
      }
    }
```


### `sasl_kerberos_service_name` [plugins-inputs-kafka-sasl_kerberos_service_name]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The Kerberos principal name that Kafka broker runs as. This can be defined either in Kafka’s JAAS config or in Kafka’s config.


### `sasl_mechanism` [plugins-inputs-kafka-sasl_mechanism]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"GSSAPI"`

[SASL mechanism](http://kafka.apache.org/documentation.md#security_sasl) used for client connections. This may be any mechanism for which a security provider is available. GSSAPI is the default mechanism.


### `schema_registry_key` [plugins-inputs-kafka-schema_registry_key]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Set the username for basic authorization to access remote Schema Registry.


### `schema_registry_proxy` [plugins-inputs-kafka-schema_registry_proxy]

* Value type is [uri](/reference/configuration-file-structure.md#uri)
* There is no default value for this setting.

Set the address of a forward HTTP proxy. An empty string is treated as if proxy was not set.


### `schema_registry_secret` [plugins-inputs-kafka-schema_registry_secret]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Set the password for basic authorization to access remote Schema Registry.


### `schema_registry_ssl_keystore_location` [plugins-inputs-kafka-schema_registry_ssl_keystore_location]

* Value type is [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting.

If schema registry client authentication is required, this setting stores the keystore path.


### `schema_registry_ssl_keystore_password` [plugins-inputs-kafka-schema_registry_ssl_keystore_password]

* Value type is [password](/reference/configuration-file-structure.md#password)
* There is no default value for this setting.

If schema registry authentication is required, this setting stores the keystore password.


### `schema_registry_ssl_keystore_type` [plugins-inputs-kafka-schema_registry_ssl_keystore_type]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The format of the keystore file. It must be either `jks` or `PKCS12`.


### `schema_registry_ssl_truststore_location` [plugins-inputs-kafka-schema_registry_ssl_truststore_location]

* Value type is [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting.

The truststore path to validate the schema registry’s certificate.


### `schema_registry_ssl_truststore_password` [plugins-inputs-kafka-schema_registry_ssl_truststore_password]

* Value type is [password](/reference/configuration-file-structure.md#password)
* There is no default value for this setting.

The schema registry truststore password.


### `schema_registry_ssl_truststore_type` [plugins-inputs-kafka-schema_registry_ssl_truststore_type]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The format of the schema registry’s truststore file. It must be either `jks` or `PKCS12`.


### `schema_registry_url` [plugins-inputs-kafka-schema_registry_url]

* Value type is [uri](/reference/configuration-file-structure.md#uri)

The URI that points to an instance of the [Schema Registry](https://docs.confluent.io/current/schema-registry/index.md) service, used to manage Avro schemas. Be sure that the Avro schemas for deserializing the data from the specified topics have been uploaded to the Schema Registry service. The schemas must follow a naming convention with the pattern <topic name>-value.

Use either the Schema Registry config option or the [`value_deserializer_class`](#plugins-inputs-kafka-value_deserializer_class) config option, but not both.


### `schema_registry_validation` [plugins-inputs-kafka-schema_registry_validation]

* Value can be either of: `auto`, `skip`
* Default value is `"auto"`

::::{note}
Under most circumstances, the default setting of `auto` should not need to be changed.
::::


When using the schema registry, by default the plugin checks connectivity and validates the schema registry, during plugin registration, before events are processed. In some circumstances, this process may fail when it tries to validate an authenticated schema registry, causing the plugin to crash. This setting allows the plugin to skip validation during registration, which allows the plugin to continue and events to be processed. Note that an incorrectly configured schema registry will still stop the plugin from processing events.


### `security_protocol` [plugins-inputs-kafka-security_protocol]

* Value can be any of: `PLAINTEXT`, `SSL`, `SASL_PLAINTEXT`, `SASL_SSL`
* Default value is `"PLAINTEXT"`

Security protocol to use, which can be either of PLAINTEXT,SSL,SASL_PLAINTEXT,SASL_SSL


### `send_buffer_bytes` [plugins-inputs-kafka-send_buffer_bytes]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `131072` (128KB).

The size of the TCP send buffer (SO_SNDBUF) to use when sending data


### `session_timeout_ms` [plugins-inputs-kafka-session_timeout_ms]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `10000` milliseconds (10 seconds).

The timeout after which, if the `poll_timeout_ms` is not invoked, the consumer is marked dead and a rebalance operation is triggered for the group identified by `group_id`


### `ssl_endpoint_identification_algorithm` [plugins-inputs-kafka-ssl_endpoint_identification_algorithm]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"https"`

The endpoint identification algorithm, defaults to `"https"`. Set to empty string `""` to disable endpoint verification


### `ssl_key_password` [plugins-inputs-kafka-ssl_key_password]

* Value type is [password](/reference/configuration-file-structure.md#password)
* There is no default value for this setting.

The password of the private key in the key store file.


### `ssl_keystore_location` [plugins-inputs-kafka-ssl_keystore_location]

* Value type is [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting.

If client authentication is required, this setting stores the keystore path.


### `ssl_keystore_password` [plugins-inputs-kafka-ssl_keystore_password]

* Value type is [password](/reference/configuration-file-structure.md#password)
* There is no default value for this setting.

If client authentication is required, this setting stores the keystore password


### `ssl_keystore_type` [plugins-inputs-kafka-ssl_keystore_type]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The format of the keystore file. It must be either `jks` or `PKCS12`.


### `ssl_truststore_location` [plugins-inputs-kafka-ssl_truststore_location]

* Value type is [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting.

The JKS truststore path to validate the Kafka broker’s certificate.


### `ssl_truststore_password` [plugins-inputs-kafka-ssl_truststore_password]

* Value type is [password](/reference/configuration-file-structure.md#password)
* There is no default value for this setting.

The truststore password.


### `ssl_truststore_type` [plugins-inputs-kafka-ssl_truststore_type]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The format of the truststore file. It must be either `jks` or `PKCS12`.


### `topics` [plugins-inputs-kafka-topics]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `["logstash"]`

A list of topics to subscribe to, defaults to ["logstash"].


### `topics_pattern` [plugins-inputs-kafka-topics_pattern]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

A topic regular expression pattern to subscribe to.

Filtering by a regular expression is done by retrieving the full list of topic names from the broker and applying the pattern locally. When used with brokers with a lot of topics this operation could be very slow, especially if there are a lot of consumers.

::::{note}
When the broker has some topics configured with ACL rules and they miss the DESCRIBE permission, then the subscription happens but on the broker side it is logged that the subscription of some topics was denied to the configured user.
::::



### `value_deserializer_class` [plugins-inputs-kafka-value_deserializer_class]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"org.apache.kafka.common.serialization.StringDeserializer"`

Java Class used to deserialize the record’s value. A custom value deserializer can be used only if you are not using a Schema Registry. Use either the value_deserializer_class config option or the [`schema_registry_url`](#plugins-inputs-kafka-schema_registry_url) config option, but not both.



## Common options [plugins-inputs-kafka-common-options]

These configuration options are supported by all input plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`add_field`](#plugins-inputs-kafka-add_field) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`codec`](#plugins-inputs-kafka-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-inputs-kafka-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-inputs-kafka-id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`tags`](#plugins-inputs-kafka-tags) | [array](/reference/configuration-file-structure.md#array) | No |
| [`type`](#plugins-inputs-kafka-type) | [string](/reference/configuration-file-structure.md#string) | No |

### `add_field` [plugins-inputs-kafka-add_field]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

Add a field to an event


### `codec` [plugins-inputs-kafka-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for input data. Input codecs are a convenient method for decoding your data before it enters the input, without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-inputs-kafka-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance by default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-inputs-kafka-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type, for example, if you have 2 kafka inputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
input {
  kafka {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::



### `tags` [plugins-inputs-kafka-tags]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

Add any number of arbitrary tags to your event.

This can help with processing later.


### `type` [plugins-inputs-kafka-type]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a `type` field to all events handled by this input.

Types are used mainly for filter activation.

The type is stored as part of the event itself, so you can also use the type to search for it in Kibana.

If you try to set a type on an event that already has one (for example when you send an event from a shipper to an indexer) then a new input will not override the existing type. A type set at the shipper stays with that event for its life even when sent to another Logstash server.



