---
navigation_title: "azure_event_hubs"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-inputs-azure_event_hubs.html
---

# Azure Event Hubs plugin [plugins-inputs-azure_event_hubs]


* Plugin version: v1.5.1
* Released on: 2025-01-03
* [Changelog](https://github.com/logstash-plugins/logstash-input-azure_event_hubs/blob/v1.5.1/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://docs/reference/input-azure_event_hubs-index.md).

## Getting help [_getting_help_8]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-input-azure_event_hubs). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_9]

This plugin consumes events from [Azure Event Hubs](https://azure.microsoft.com/en-us/services/event-hubs), a highly scalable data streaming platform and event ingestion service. Event producers send events to the Azure Event Hub, and this plugin consumes those events for use with Logstash.

Many Azure services integrate with the Azure Event Hubs. [Azure Monitor](https://docs.microsoft.com/en-us/azure/monitoring-and-diagnostics/monitoring-overview-azure-monitor), for example, integrates with Azure Event Hubs to provide infrastructure metrics.

::::{important}
This plugin requires outbound connections to ports `tcp/443`, `tcp/9093`, `tcp/5671`, and `tcp/5672`, as noted in the [Microsoft Event Hub documentation](https://learn.microsoft.com/en-us/azure/event-hubs/event-hubs-faq#what-ports-do-i-need-to-open-on-the-firewall).
::::


### Event Hub connection string [_event_hub_connection_string]

The plugin uses the connection string to access Azure Events Hubs. Find the connection string here: [Azure Portal](https://portal.azure.com)`-> Event Hub -> Shared access polices`. The event_hub_connections option passes the Event Hub connection strings for the basic configuration.

Sample connection string:

```text
Endpoint=sb://logstash.servicebus.windows.net/;SharedAccessKeyName=activity-log-read-only;SharedAccessKey=mm6AbDcEfj8lk7sjsbzoTJ10qAkiSaG663YykEAG2eg=;EntityPath=insights-operational-logs
```


### Blob Storage and connection string [_blob_storage_and_connection_string]

[Azure Blob Storage account](https://azure.microsoft.com/en-us/services/storage/blobs) is an essential part of Azure-to-Logstash configuration. A Blob Storage account is a central location that enables multiple instances of Logstash to work together to process events. It records the offset (location) of processed events. On restart, Logstash resumes processing exactly where it left off.

Configuration notes:

* A Blob Storage account is highly recommended for use with this plugin, and is likely required for production servers.
* The `storage_connection` option passes the blob storage connection string.
* Configure all Logstash instances to use the same `storage_connection` to get the benefits of shared processing.

Sample Blob Storage connection string:

```text
DefaultEndpointsProtocol=https;AccountName=logstash;AccountKey=ETOPnkd/hDAWidkEpPZDiXffQPku/SZdXhPSLnfqdRTalssdEuPkZwIcouzXjCLb/xPZjzhmHfwRCGo0SBSw==;EndpointSuffix=core.windows.net
```

Find the connection string to Blob Storage here: [Azure Portal](https://portal.azure.com)`-> Blob Storage account -> Access keys`.


### Best practices [plugins-inputs-azure_event_hubs-best-practices]

Here are some guidelines to help you avoid data conflicts that can cause lost events.

* [Create a Logstash consumer group](#plugins-inputs-azure_event_hubs-bp-group)
* [Avoid overwriting offset with multiple Event Hubs](#plugins-inputs-azure_event_hubs-bp-multihub)
* [Set number of threads correctly](#plugins-inputs-azure_event_hubs-bp-threads)

#### Create a Logstash consumer group [plugins-inputs-azure_event_hubs-bp-group]

Create a new consumer group specifically for Logstash. Do not use the $default or any other consumer group that might already be in use. Reusing consumer groups among non-related consumers can cause unexpected behavior and possibly lost events. All Logstash instances should use the same consumer group so that they can work together for processing events.


#### Avoid overwriting offset with multiple Event Hubs [plugins-inputs-azure_event_hubs-bp-multihub]

The offsets (position) of the Event Hubs are stored in the configured Azure Blob store. The Azure Blob store uses paths like a file system to store the offsets. If the paths between multiple Event Hubs overlap, then the offsets may be stored incorrectly.

To avoid duplicate file paths, use the advanced configuration model and make sure that at least one of these options is different per Event Hub:

* storage_connection
* storage_container (defaults to Event Hub name if not defined)
* consumer_group


#### Set number of threads correctly [plugins-inputs-azure_event_hubs-bp-threads]

By default, the number of threads used to service all event hubs is `16`. And while this may be sufficient for most use cases, throughput may be improved by refining this number. When servicing a large number of partitions across one or more event hubs, setting a higher value may result in improved performance. The maximum number of threads is not strictly bound by the total number of partitions being serviced, but setting the value much higher than that may mean that some threads are idle.

::::{note}
The number of threads **must** be greater than or equal to the number of Event hubs plus one.
::::


::::{note}
Threads are currently available only as a global setting across all event hubs in a single `azure_event_hubs` input definition. However if your configuration includes multiple `azure_event_hubs` inputs, the threads setting applies independently to each.
::::


**Example: Single event hub**

If you’re collecting activity logs from one event hub instance, then only 2 threads are required.

* Event hubs = 1
* Minimum threads = 2 (1 Event Hub + 1)

**Example: Multiple event hubs**

If you are collecting activity logs from more than event hub instance, then at least 1 thread per event hub is required.

* Event hubs = 4
* Minimum threads = 5 (4 Event Hubs + 1)

When you are using multiple partitions per event hub, you may want to assign more threads. A good base level is (1 + `number of event hubs * number of partitions`). That is, one thread for each partition across all event hubs.




## Configuration models [plugins-inputs-azure_event_hubs-eh_config_models]

This plugin supports two configuration models: basic and advanced. Basic configuration is recommended for most use cases, and is illustrated in the examples throughout this topic.

### Basic configuration (default) [plugins-inputs-azure_event_hubs-eh_basic_config]

Basic configuration is the default and supports consuming from multiple Event Hubs. All Events Hubs, except for the connection string, share the same configuration.

You supply a list of Event Hub connection strings, complete with the Event Hub EntityPath that defines the Event Hub name. All other configuration settings are shared.

```ruby
input {
   azure_event_hubs {
      event_hub_connections => ["Endpoint=sb://example1...EntityPath=insights-logs-errors", "Endpoint=sb://example2...EntityPath=insights-metrics-pt1m"]
      threads => 8
      decorate_events => true
      consumer_group => "logstash"
      storage_connection => "DefaultEndpointsProtocol=https;AccountName=example...."
   }
}
```


### Advanced configuration [plugins-inputs-azure_event_hubs-eh_advanced_config]

The advanced configuration model accommodates deployments where different Event Hubs require different configurations. Options can be configured per Event Hub. You provide a list of Event Hub names through the `event_hubs` option. Under each name, specify the configuration for that Event Hub. Options can be defined globally or expressed per Event Hub.

If the same configuration option appears in both the global and `event_hub` sections, the more specific (event_hub) setting takes precedence.

::::{note}
Advanced configuration is not necessary or recommended for most use cases.
::::


```ruby
input {
   azure_event_hubs {
     config_mode => "advanced"
     threads => 8
     decorate_events => true
     storage_connection => "DefaultEndpointsProtocol=https;AccountName=example...."
     event_hubs => [
        {"insights-operational-logs" => {
         event_hub_connection => "Endpoint=sb://example1..."
         initial_position => "beginning"
         consumer_group => "iam_team"
        }},
      {"insights-metrics-pt1m" => {
         event_hub_connection => "Endpoint=sb://example2..."
         initial_position => "end"
         consumer_group => "db_team"
       }}
     ]
   }
}
```

In this example, `storage_connection` and `decorate_events` are applied globally. The two Event Hubs each have their own  settings for `consumer_groups` and `initial_position`.



## Azure Event Hubs Configuration Options [plugins-inputs-azure_event_hubs-options]

This plugin supports the following configuration options plus the [Common options](#plugins-inputs-azure_event_hubs-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`config_mode`](#plugins-inputs-azure_event_hubs-config_mode) | [string](/reference/configuration-file-structure.md#string), (`basic` or `advanced`) | No |
| [`event_hubs`](#plugins-inputs-azure_event_hubs-event_hubs) | [array](/reference/configuration-file-structure.md#array) | Yes, when `config_mode => advanced` |
| [`event_hub_connections`](#plugins-inputs-azure_event_hubs-event_hub_connections) | [array](/reference/configuration-file-structure.md#array) | Yes, when `config_mode => basic` |
| [`event_hub_connection`](#plugins-inputs-azure_event_hubs-event_hub_connection) | [string](/reference/configuration-file-structure.md#string) | Yes, when `config_mode => advanced` |
| [`checkpoint_interval`](#plugins-inputs-azure_event_hubs-checkpoint_interval) | [number](/reference/configuration-file-structure.md#number) | No |
| [`consumer_group`](#plugins-inputs-azure_event_hubs-consumer_group) | [string](/reference/configuration-file-structure.md#string) | No |
| [`decorate_events`](#plugins-inputs-azure_event_hubs-decorate_events) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`initial_position`](#plugins-inputs-azure_event_hubs-initial_position) | [string](/reference/configuration-file-structure.md#string), (`beginning`, `end`, or `look_back`) | No |
| [`initial_position_look_back`](#plugins-inputs-azure_event_hubs-initial_position_look_back) | [number](/reference/configuration-file-structure.md#number) | No, unless `initial_position => look_back` |
| [`max_batch_size`](#plugins-inputs-azure_event_hubs-max_batch_size) | [number](/reference/configuration-file-structure.md#number) | No |
| [`storage_connection`](#plugins-inputs-azure_event_hubs-storage_connection) | [string](/reference/configuration-file-structure.md#string) | No |
| [`storage_container`](#plugins-inputs-azure_event_hubs-storage_container) | [string](/reference/configuration-file-structure.md#string) | No |
| [`threads`](#plugins-inputs-azure_event_hubs-threads) | [number](/reference/configuration-file-structure.md#number) | No |

Also see [Common options](#plugins-inputs-azure_event_hubs-common-options) for a list of options supported by all input plugins.

::::{note}
All Event Hubs options are common to both basic and advanced configurations, with the following exceptions. The basic configuration uses `event_hub_connections` to support multiple connections. The advanced configuration uses `event_hubs` and `event_hub_connection` (singular).
::::


### `config_mode` [plugins-inputs-azure_event_hubs-config_mode]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Valid entries are `basic` or `advanced`
* Default value is `basic`

Sets configuration to either [Basic configuration (default)](#plugins-inputs-azure_event_hubs-eh_basic_config) or [Advanced configuration](#plugins-inputs-azure_event_hubs-eh_advanced_config).

```ruby
azure_event_hubs {
   event_hub_connections => ["Endpoint=sb://example1...;EntityPath=event_hub_name1"  , "Endpoint=sb://example2...;EntityPath=event_hub_name2"  ]
}
```


### `event_hubs` [plugins-inputs-azure_event_hubs-event_hubs]

* Value type is [array](/reference/configuration-file-structure.md#array)
* No default value
* Ignored for basic configuration
* Required for advanced configuration

Defines the Event Hubs to be read. An array of hashes where each entry is a hash of the Event Hub name and its configuration options.

```ruby
azure_event_hubs {
  config_mode => "advanced"
  event_hubs => [
      { "event_hub_name1" => {
          event_hub_connection => "Endpoint=sb://example1..."
      }},
      { "event_hub_name2" => {
          event_hub_connection => "Endpoint=sb://example2..."
          storage_connection => "DefaultEndpointsProtocol=https;AccountName=example...."
          storage_container => "my_container"
     }}
   ]
   consumer_group => "logstash" # shared across all Event Hubs
}
```


### `event_hub_connections` [plugins-inputs-azure_event_hubs-event_hub_connections]

* Value type is [array](/reference/configuration-file-structure.md#array)
* No default value
* Required for basic configuration

List of connection strings that identifies the Event Hubs to be read. Connection strings include the EntityPath for the Event Hub.

The `event_hub_connections` option is defined per Event Hub. All other configuration options are shared among Event Hubs.

```ruby
azure_event_hubs {
   event_hub_connections => ["Endpoint=sb://example1...;EntityPath=event_hub_name1"  , "Endpoint=sb://example2...;EntityPath=event_hub_name2"  ]
}
```


### `event_hub_connection` [plugins-inputs-azure_event_hubs-event_hub_connection]

* Value type is [string](/reference/configuration-file-structure.md#string)
* No default value
* Valid only for advanced configuration

Connection string that identifies the Event Hub to be read. Advanced configuration options can be set per Event Hub. This option modifies `event_hub_name`, and should be nested under it. (See sample.) This option accepts only one connection string.

```ruby
azure_event_hubs {
   config_mode => "advanced"
   event_hubs => [
     { "event_hub_name1" => {
        event_hub_connection => "Endpoint=sb://example1...;EntityPath=event_hub_name1"
     }}
   ]
}
```


### `checkpoint_interval` [plugins-inputs-azure_event_hubs-checkpoint_interval]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `5` seconds
* Set to `0` to disable.

Interval in seconds to write checkpoints during batch processing. Checkpoints tell Logstash where to resume processing after a restart. Checkpoints are automatically written at the end of each batch, regardless of this setting.

Writing checkpoints too frequently can slow down processing unnecessarily.

```ruby
azure_event_hubs {
   event_hub_connections => ["Endpoint=sb://example1...;EntityPath=event_hub_name1"]
   checkpoint_interval => 5
}
```


### `consumer_group` [plugins-inputs-azure_event_hubs-consumer_group]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `$Default`

Consumer group used to read the Event Hub(s). Create a consumer group specifically for Logstash. Then ensure that all instances of Logstash use that consumer group so that they can work together properly.

```ruby
azure_event_hubs {
   event_hub_connections => ["Endpoint=sb://example1...;EntityPath=event_hub_name1"]
   consumer_group => "logstash"
}
```


### `decorate_events` [plugins-inputs-azure_event_hubs-decorate_events]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Adds metadata about the Event Hub, including Event Hub name, consumer_group, processor_host, partition, offset, sequence, timestamp, and event_size.

```ruby
azure_event_hubs {
   event_hub_connections => ["Endpoint=sb://example1...;EntityPath=event_hub_name1"]
   decorate_events => true
}
```


### `initial_position` [plugins-inputs-azure_event_hubs-initial_position]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Valid arguments are `beginning`, `end`, `look_back`
* Default value is `beginning`

When first reading from an Event Hub, start from this position:

* `beginning` reads all pre-existing events in the Event Hub
* `end` does not read any pre-existing events in the Event Hub
* `look_back` reads `end` minus a number of seconds worth of pre-existing events. You control the number of seconds using the `initial_position_look_back` option.

Note: If `storage_connection` is set, the `initial_position` value is used only the first time Logstash reads from the Event Hub.

```ruby
azure_event_hubs {
   event_hub_connections => ["Endpoint=sb://example1...;EntityPath=event_hub_name1"]
   initial_position => "beginning"
}
```


### `initial_position_look_back` [plugins-inputs-azure_event_hubs-initial_position_look_back]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `86400`
* Used only if `initial_position` is set to `look-back`

Number of seconds to look back to find the initial position for pre-existing events. This option is used only if `initial_position` is set to `look_back`. If `storage_connection` is set, this configuration applies only the first time Logstash reads from the Event Hub.

```ruby
azure_event_hubs {
   event_hub_connections => ["Endpoint=sb://example1...;EntityPath=event_hub_name1"]
   initial_position => "look_back"
   initial_position_look_back => 86400
}
```


### `max_batch_size` [plugins-inputs-azure_event_hubs-max_batch_size]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `125`

Maximum number of events retrieved and processed together. A checkpoint is created after each batch. Increasing this value may help with performance, but requires more memory.

```ruby
azure_event_hubs {
   event_hub_connections => ["Endpoint=sb://example1...;EntityPath=event_hub_name1"]
   max_batch_size => 125
}
```


### `storage_connection` [plugins-inputs-azure_event_hubs-storage_connection]

* Value type is [string](/reference/configuration-file-structure.md#string)
* No default value

Connection string for blob account storage. Blob account storage persists the offsets between restarts, and ensures that multiple instances of Logstash process different partitions. When this value is set, restarts resume where processing left off. When this value is not set, the `initial_position` value is used on every restart.

We strongly recommend that you define this value for production environments.

```ruby
azure_event_hubs {
   event_hub_connections => ["Endpoint=sb://example1...;EntityPath=event_hub_name1"]
   storage_connection => "DefaultEndpointsProtocol=https;AccountName=example...."
}
```


### `storage_container` [plugins-inputs-azure_event_hubs-storage_container]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Defaults to the Event Hub name if not defined

Name of the storage container used to persist offsets and allow multiple instances of Logstash to work together.

```ruby
azure_event_hubs {
   event_hub_connections => ["Endpoint=sb://example1...;EntityPath=event_hub_name1"]
   storage_connection => "DefaultEndpointsProtocol=https;AccountName=example...."
   storage_container => "my_container"
}
```

To avoid overwriting offsets, you can use different storage containers. This is particularly important if you are monitoring two Event Hubs with the same name. You can use the advanced configuration model to configure different storage containers.

```ruby
azure_event_hubs {
     config_mode => "advanced"
     consumer_group => "logstash"
     storage_connection => "DefaultEndpointsProtocol=https;AccountName=example...."
     event_hubs => [
        {"insights-operational-logs" => {
         event_hub_connection => "Endpoint=sb://example1..."
         storage_container => "insights-operational-logs-1"
        }},
        {"insights-operational-logs" => {
         event_hub_connection => "Endpoint=sb://example2..."
         storage_container => "insights-operational-logs-2"
        }}
     ]
   }
```


### `threads` [plugins-inputs-azure_event_hubs-threads]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Minimum value is `2`
* Default value is `16`

Total number of threads used to process events. The value you set here applies to all Event Hubs. Even with advanced configuration, this value is a global setting, and can’t be set per event hub.

```ruby
azure_event_hubs {
   threads => 16
}
```

The number of threads should be the number of Event Hubs plus one or more. See [Best practices](#plugins-inputs-azure_event_hubs-best-practices) for more information.



## Common options [plugins-inputs-azure_event_hubs-common-options]

These configuration options are supported by all input plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`add_field`](#plugins-inputs-azure_event_hubs-add_field) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`codec`](#plugins-inputs-azure_event_hubs-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-inputs-azure_event_hubs-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-inputs-azure_event_hubs-id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`tags`](#plugins-inputs-azure_event_hubs-tags) | [array](/reference/configuration-file-structure.md#array) | No |
| [`type`](#plugins-inputs-azure_event_hubs-type) | [string](/reference/configuration-file-structure.md#string) | No |

### `add_field` [plugins-inputs-azure_event_hubs-add_field]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

Add a field to an event


### `codec` [plugins-inputs-azure_event_hubs-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for input data. Input codecs are a convenient method for decoding your data before it enters the input, without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-inputs-azure_event_hubs-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance by default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-inputs-azure_event_hubs-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type, for example, if you have 2 azure_event_hubs inputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
input {
  azure_event_hubs {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::



### `tags` [plugins-inputs-azure_event_hubs-tags]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

Add any number of arbitrary tags to your event.

This can help with processing later.


### `type` [plugins-inputs-azure_event_hubs-type]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a `type` field to all events handled by this input.

Types are used mainly for filter activation.

The type is stored as part of the event itself, so you can also use the type to search for it in Kibana.

If you try to set a type on an event that already has one (for example when you send an event from a shipper to an indexer) then a new input will not override the existing type. A type set at the shipper stays with that event for its life even when sent to another Logstash server.
