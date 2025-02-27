---
navigation_title: "ganglia"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-inputs-ganglia.html
---

# Ganglia input plugin [plugins-inputs-ganglia]


* Plugin version: v3.1.4
* Released on: 2018-04-06
* [Changelog](https://github.com/logstash-plugins/logstash-input-ganglia/blob/v3.1.4/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://docs/reference/input-ganglia-index.md).

## Getting help [_getting_help_18]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-input-ganglia). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_19]

Read ganglia packets from the network via udp


## Ganglia Input Configuration Options [plugins-inputs-ganglia-options]

This plugin supports the following configuration options plus the [Common options](#plugins-inputs-ganglia-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`host`](#plugins-inputs-ganglia-host) | [string](/reference/configuration-file-structure.md#string) | No |
| [`port`](#plugins-inputs-ganglia-port) | [number](/reference/configuration-file-structure.md#number) | No |

Also see [Common options](#plugins-inputs-ganglia-common-options) for a list of options supported by all input plugins.

 

### `host` [plugins-inputs-ganglia-host]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"0.0.0.0"`

The address to listen on


### `port` [plugins-inputs-ganglia-port]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `8649`

The port to listen on. Remember that ports less than 1024 (privileged ports) may require root to use.



## Common options [plugins-inputs-ganglia-common-options]

These configuration options are supported by all input plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`add_field`](#plugins-inputs-ganglia-add_field) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`codec`](#plugins-inputs-ganglia-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-inputs-ganglia-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-inputs-ganglia-id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`tags`](#plugins-inputs-ganglia-tags) | [array](/reference/configuration-file-structure.md#array) | No |
| [`type`](#plugins-inputs-ganglia-type) | [string](/reference/configuration-file-structure.md#string) | No |

### `add_field` [plugins-inputs-ganglia-add_field]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

Add a field to an event


### `codec` [plugins-inputs-ganglia-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for input data. Input codecs are a convenient method for decoding your data before it enters the input, without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-inputs-ganglia-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance by default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-inputs-ganglia-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type, for example, if you have 2 ganglia inputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
input {
  ganglia {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::



### `tags` [plugins-inputs-ganglia-tags]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

Add any number of arbitrary tags to your event.

This can help with processing later.


### `type` [plugins-inputs-ganglia-type]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a `type` field to all events handled by this input.

Types are used mainly for filter activation.

The type is stored as part of the event itself, so you can also use the type to search for it in Kibana.

If you try to set a type on an event that already has one (for example when you send an event from a shipper to an indexer) then a new input will not override the existing type. A type set at the shipper stays with that event for its life even when sent to another Logstash server.



