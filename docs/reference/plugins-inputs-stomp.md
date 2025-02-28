---
navigation_title: "stomp"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-inputs-stomp.html
---

# Stomp input plugin [plugins-inputs-stomp]


* Plugin version: v3.0.8
* Released on: 2018-04-06
* [Changelog](https://github.com/logstash-plugins/logstash-input-stomp/blob/v3.0.8/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://reference/input-stomp-index.md).

## Installation [_installation_16]

For plugins not bundled by default, it is easy to install by running `bin/logstash-plugin install logstash-input-stomp`. See [Working with plugins](/reference/working-with-plugins.md) for more details.


## Getting help [_getting_help_55]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-input-stomp). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_55]

Creates events received with the STOMP protocol.


## Stomp Input Configuration Options [plugins-inputs-stomp-options]

This plugin supports the following configuration options plus the [Common options](#plugins-inputs-stomp-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`destination`](#plugins-inputs-stomp-destination) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`host`](#plugins-inputs-stomp-host) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`password`](#plugins-inputs-stomp-password) | [password](/reference/configuration-file-structure.md#password) | No |
| [`port`](#plugins-inputs-stomp-port) | [number](/reference/configuration-file-structure.md#number) | No |
| [`reconnect`](#plugins-inputs-stomp-reconnect) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`reconnect_interval`](#plugins-inputs-stomp-reconnect_interval) | [number](/reference/configuration-file-structure.md#number) | No |
| [`user`](#plugins-inputs-stomp-user) | [string](/reference/configuration-file-structure.md#string) | No |
| [`vhost`](#plugins-inputs-stomp-vhost) | [string](/reference/configuration-file-structure.md#string) | No |

Also see [Common options](#plugins-inputs-stomp-common-options) for a list of options supported by all input plugins.

 

### `destination` [plugins-inputs-stomp-destination]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The destination to read events from.

Example: `/topic/logstash`


### `host` [plugins-inputs-stomp-host]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"localhost"`

The address of the STOMP server.


### `password` [plugins-inputs-stomp-password]

* Value type is [password](/reference/configuration-file-structure.md#password)
* Default value is `""`

The password to authenticate with.


### `port` [plugins-inputs-stomp-port]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `61613`

The port to connet to on your STOMP server.


### `reconnect` [plugins-inputs-stomp-reconnect]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Auto reconnect


### `reconnect_interval` [plugins-inputs-stomp-reconnect_interval]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `30`


### `user` [plugins-inputs-stomp-user]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `""`

The username to authenticate with.


### `vhost` [plugins-inputs-stomp-vhost]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `nil`

The vhost to use



## Common options [plugins-inputs-stomp-common-options]

These configuration options are supported by all input plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`add_field`](#plugins-inputs-stomp-add_field) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`codec`](#plugins-inputs-stomp-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-inputs-stomp-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-inputs-stomp-id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`tags`](#plugins-inputs-stomp-tags) | [array](/reference/configuration-file-structure.md#array) | No |
| [`type`](#plugins-inputs-stomp-type) | [string](/reference/configuration-file-structure.md#string) | No |

### `add_field` [plugins-inputs-stomp-add_field]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

Add a field to an event


### `codec` [plugins-inputs-stomp-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for input data. Input codecs are a convenient method for decoding your data before it enters the input, without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-inputs-stomp-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance by default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-inputs-stomp-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type, for example, if you have 2 stomp inputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
input {
  stomp {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::



### `tags` [plugins-inputs-stomp-tags]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

Add any number of arbitrary tags to your event.

This can help with processing later.


### `type` [plugins-inputs-stomp-type]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a `type` field to all events handled by this input.

Types are used mainly for filter activation.

The type is stored as part of the event itself, so you can also use the type to search for it in Kibana.

If you try to set a type on an event that already has one (for example when you send an event from a shipper to an indexer) then a new input will not override the existing type. A type set at the shipper stays with that event for its life even when sent to another Logstash server.



