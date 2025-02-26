---
navigation_title: "udp"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-inputs-udp.html
---

# Udp input plugin [plugins-inputs-udp]


* Plugin version: v3.5.0
* Released on: 2021-08-04
* [Changelog](https://github.com/logstash-plugins/logstash-input-udp/blob/v3.5.0/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://docs/reference/input-udp-index.md).

## Getting help [_getting_help_59]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-input-udp). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_59]

Read messages as events over the network via udp. The only required configuration item is `port`, which specifies the udp port logstash will listen on for event streams.

### Event Metadata and the Elastic Common Schema (ECS) [plugins-inputs-udp-ecs_metadata]

This plugin adds a field containing the source IP address of the UDP packet. By default, the IP address is stored in the host field. When [Elastic Common Schema (ECS)][Elastic Common Schema (ECS)](ecs://docs/reference/index.md)) is enabled (in [`ecs_compatibility`](#plugins-inputs-udp-ecs_compatibility)), the source IP address is stored in the [host][ip] field.

You can customize the field name using the [`source_ip_fieldname`](#plugins-inputs-udp-source_ip_fieldname). See [`ecs_compatibility`](#plugins-inputs-udp-ecs_compatibility) for more information.



## Udp Input Configuration Options [plugins-inputs-udp-options]

This plugin supports the following configuration options plus the [Common options](#plugins-inputs-udp-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`buffer_size`](#plugins-inputs-udp-buffer_size) | [number](/reference/configuration-file-structure.md#number) | No |
| [`ecs_compatibility`](#plugins-inputs-udp-ecs_compatibility) | [string](/reference/configuration-file-structure.md#string) | No |
| [`host`](#plugins-inputs-udp-host) | [string](/reference/configuration-file-structure.md#string) | No |
| [`port`](#plugins-inputs-udp-port) | [number](/reference/configuration-file-structure.md#number) | Yes |
| [`queue_size`](#plugins-inputs-udp-queue_size) | [number](/reference/configuration-file-structure.md#number) | No |
| [`receive_buffer_bytes`](#plugins-inputs-udp-receive_buffer_bytes) | [number](/reference/configuration-file-structure.md#number) | No |
| [`source_ip_fieldname`](#plugins-inputs-udp-source_ip_fieldname) | [string](/reference/configuration-file-structure.md#string) | No |
| [`workers`](#plugins-inputs-udp-workers) | [number](/reference/configuration-file-structure.md#number) | No |

Also see [Common options](#plugins-inputs-udp-common-options) for a list of options supported by all input plugins.

 

### `buffer_size` [plugins-inputs-udp-buffer_size]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `65536`

The maximum packet size to read from the network


### `ecs_compatibility` [plugins-inputs-udp-ecs_compatibility]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Supported values are:

    * `disabled`: unstructured connection metadata added at root level
    * `v1`: structured connection metadata added under ECS compliant namespaces

* Default value depends on which version of Logstash is running:

    * When Logstash provides a `pipeline.ecs_compatibility` setting, its value is used as the default
    * Otherwise, the default value is `disabled`.


Controls this plugin’s compatibility with the [Elastic Common Schema (ECS)][Elastic Common Schema (ECS)](ecs://docs/reference/index.md)).

The value of this setting affects the placement of a TCP connection’s metadata on events.

| `disabled` | `v1` | Availability | Description |
| --- | --- | --- | --- |
| host | [host][ip] | *Always* | *Source IP of UDP packet* |


### `host` [plugins-inputs-udp-host]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"0.0.0.0"`

The address which logstash will listen on.


### `port` [plugins-inputs-udp-port]

* This is a required setting.
* Value type is [number](/reference/configuration-file-structure.md#number)
* There is no default value for this setting.

The port which logstash will listen on. Remember that ports less than 1024 (privileged ports) may require root or elevated privileges to use.


### `queue_size` [plugins-inputs-udp-queue_size]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `2000`

This is the number of unprocessed UDP packets you can hold in memory before packets will start dropping.


### `receive_buffer_bytes` [plugins-inputs-udp-receive_buffer_bytes]

* Value type is [number](/reference/configuration-file-structure.md#number)
* There is no default value for this setting.

The socket receive buffer size in bytes. If option is not set, the operating system default is used. The operating system will use the max allowed value if receive_buffer_bytes is larger than allowed. Consult your operating system documentation if you need to increase this max allowed value.


### `source_ip_fieldname` [plugins-inputs-udp-source_ip_fieldname]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value could be `"host"` or `[host][ip]` depending on the value of [`ecs_compatibility`](#plugins-inputs-udp-ecs_compatibility)

The name of the field where the source IP address will be stored. See [Event Metadata and the Elastic Common Schema (ECS)](#plugins-inputs-udp-ecs_metadata) for more information on how ECS compatibility settings affect these defaults.

Example:

```ruby
    input {
      udp {
        source_ip_fieldname => "[appliance][monitoring][ip]"
      }
    }
```


### `workers` [plugins-inputs-udp-workers]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `2`

Number of threads processing packets



## Common options [plugins-inputs-udp-common-options]

These configuration options are supported by all input plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`add_field`](#plugins-inputs-udp-add_field) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`codec`](#plugins-inputs-udp-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-inputs-udp-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-inputs-udp-id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`tags`](#plugins-inputs-udp-tags) | [array](/reference/configuration-file-structure.md#array) | No |
| [`type`](#plugins-inputs-udp-type) | [string](/reference/configuration-file-structure.md#string) | No |

### `add_field` [plugins-inputs-udp-add_field]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

Add a field to an event


### `codec` [plugins-inputs-udp-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for input data. Input codecs are a convenient method for decoding your data before it enters the input, without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-inputs-udp-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance by default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-inputs-udp-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type, for example, if you have 2 udp inputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
input {
  udp {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::



### `tags` [plugins-inputs-udp-tags]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

Add any number of arbitrary tags to your event.

This can help with processing later.


### `type` [plugins-inputs-udp-type]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a `type` field to all events handled by this input.

Types are used mainly for filter activation.

The type is stored as part of the event itself, so you can also use the type to search for it in Kibana.

If you try to set a type on an event that already has one (for example when you send an event from a shipper to an indexer) then a new input will not override the existing type. A type set at the shipper stays with that event for its life even when sent to another Logstash server.



