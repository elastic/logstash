---
navigation_title: "gelf"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-inputs-gelf.html
---

# Gelf input plugin [plugins-inputs-gelf]


* Plugin version: v3.3.2
* Released on: 2022-08-22
* [Changelog](https://github.com/logstash-plugins/logstash-input-gelf/blob/v3.3.2/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://docs/reference/input-gelf-index.md).

## Getting help [_getting_help_19]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-input-gelf). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_20]

This input will read GELF messages as events over the network, making it a good choice if you already use Graylog2 today.

The main use case for this input is to leverage existing GELF logging libraries such as the GELF log4j appender.


## Gelf Input Configuration Options [plugins-inputs-gelf-options]

This plugin supports the following configuration options plus the [Common options](#plugins-inputs-gelf-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`host`](#plugins-inputs-gelf-host) | [string](/reference/configuration-file-structure.md#string) | No |
| [`use_udp`](#plugins-inputs-gelf-use_udp) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`use_tcp`](#plugins-inputs-gelf-use_tcp) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`port`](#plugins-inputs-gelf-port) | [number](/reference/configuration-file-structure.md#number) | No |
| [`port_tcp`](#plugins-inputs-gelf-port_tcp) | [number](/reference/configuration-file-structure.md#number) | No |
| [`port_udp`](#plugins-inputs-gelf-port_udp) | [number](/reference/configuration-file-structure.md#number) | No |
| [`remap`](#plugins-inputs-gelf-remap) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`strip_leading_underscore`](#plugins-inputs-gelf-strip_leading_underscore) | [boolean](/reference/configuration-file-structure.md#boolean) | No |

Also see [Common options](#plugins-inputs-gelf-common-options) for a list of options supported by all input plugins.

 

### `host` [plugins-inputs-gelf-host]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"0.0.0.0"`

The IP address or hostname to listen on.


### `use_udp` [plugins-inputs-gelf-use_udp]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Whether to listen for gelf messages sent over udp


### `use_tcp` [plugins-inputs-gelf-use_tcp]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Whether to listen for gelf messages sent over tcp


### `port` [plugins-inputs-gelf-port]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `12201`

The port to listen on. Remember that ports less than 1024 (privileged ports) may require root to use. port_tcp and port_udp can be used to set a specific port for each protocol.


### `port_tcp` [plugins-inputs-gelf-port_tcp]

* Value type is [number](/reference/configuration-file-structure.md#number)
* There is no default value for this setting.

Tcp port to listen on. Use port instead of this setting unless you need a different port for udp than tcp


### `port_udp` [plugins-inputs-gelf-port_udp]

* Value type is [number](/reference/configuration-file-structure.md#number)
* There is no default value for this setting.

Udp port to listen on. Use port instead of this setting unless you need a different port for udp than tcp


### `remap` [plugins-inputs-gelf-remap]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Whether or not to remap the GELF message fields to Logstash event fields or leave them intact.

Remapping converts the following GELF fields to Logstash equivalents:

* `full\_message` becomes `event.get("message")`.
* if there is no `full\_message`, `short\_message` becomes `event.get("message")`.


### `strip_leading_underscore` [plugins-inputs-gelf-strip_leading_underscore]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Whether or not to remove the leading `\_` in GELF fields or leave them in place. (Logstash < 1.2 did not remove them by default.). Note that GELF version 1.1 format now requires all non-standard fields to be added as an "additional" field, beginning with an underscore.

e.g. `\_foo` becomes `foo`



## Common options [plugins-inputs-gelf-common-options]

These configuration options are supported by all input plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`add_field`](#plugins-inputs-gelf-add_field) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`codec`](#plugins-inputs-gelf-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-inputs-gelf-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-inputs-gelf-id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`tags`](#plugins-inputs-gelf-tags) | [array](/reference/configuration-file-structure.md#array) | No |
| [`type`](#plugins-inputs-gelf-type) | [string](/reference/configuration-file-structure.md#string) | No |

### `add_field` [plugins-inputs-gelf-add_field]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

Add a field to an event


### `codec` [plugins-inputs-gelf-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for input data. Input codecs are a convenient method for decoding your data before it enters the input, without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-inputs-gelf-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance by default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-inputs-gelf-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type, for example, if you have 2 gelf inputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
input {
  gelf {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::



### `tags` [plugins-inputs-gelf-tags]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

Add any number of arbitrary tags to your event.

This can help with processing later.


### `type` [plugins-inputs-gelf-type]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a `type` field to all events handled by this input.

Types are used mainly for filter activation.

The type is stored as part of the event itself, so you can also use the type to search for it in Kibana.

If you try to set a type on an event that already has one (for example when you send an event from a shipper to an indexer) then a new input will not override the existing type. A type set at the shipper stays with that event for its life even when sent to another Logstash server.



