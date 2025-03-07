---
navigation_title: "lumberjack"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-inputs-lumberjack.html
---

# Lumberjack input plugin [plugins-inputs-lumberjack]


* Plugin version: v3.1.6
* Released on: 2019-04-15
* [Changelog](https://github.com/logstash-plugins/logstash-input-lumberjack/blob/v3.1.6/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://reference/input-lumberjack-index.md).

## Installation [_installation_8]

For plugins not bundled by default, it is easy to install by running `bin/logstash-plugin install logstash-input-lumberjack`. See [Working with plugins](/reference/working-with-plugins.md) for more details.


## Getting help [_getting_help_39]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-input-lumberjack). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_39]

Receive events using the Lumberjack protocol.

This input can be used to reliably and securely transport events between Logstash instances. To do so, use the [lumberjack output plugin](/reference/plugins-outputs-lumberjack.md) in the sending Logstash instance(s).

It can also be used to receive events from the deprecated [logstash-forwarder](https://github.com/elastic/logstash-forwarder) tool that has been replaced by [Filebeat](https://github.com/elastic/beats/tree/master/filebeat).

::::{note}
Consider using the [Beats input plugin](/reference/plugins-inputs-beats.md) instead. The Beats input implements the Lumberjack protocol v1 and v2.
::::



## Lumberjack Input Configuration Options [plugins-inputs-lumberjack-options]

This plugin supports the following configuration options plus the [Common options](#plugins-inputs-lumberjack-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`congestion_threshold`](#plugins-inputs-lumberjack-congestion_threshold) | [number](/reference/configuration-file-structure.md#number) | No |
| [`host`](#plugins-inputs-lumberjack-host) | [string](/reference/configuration-file-structure.md#string) | No |
| [`port`](#plugins-inputs-lumberjack-port) | [number](/reference/configuration-file-structure.md#number) | Yes |
| [`ssl_certificate`](#plugins-inputs-lumberjack-ssl_certificate) | a valid filesystem path | Yes |
| [`ssl_key`](#plugins-inputs-lumberjack-ssl_key) | a valid filesystem path | Yes |
| [`ssl_key_passphrase`](#plugins-inputs-lumberjack-ssl_key_passphrase) | [password](/reference/configuration-file-structure.md#password) | No |

Also see [Common options](#plugins-inputs-lumberjack-common-options) for a list of options supported by all input plugins.

 

### `congestion_threshold` [plugins-inputs-lumberjack-congestion_threshold]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `5`

The number of seconds before we raise a timeout, this option is useful to control how much time to wait if something is blocking the pipeline.


### `host` [plugins-inputs-lumberjack-host]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"0.0.0.0"`

The IP address to listen on.


### `port` [plugins-inputs-lumberjack-port]

* This is a required setting.
* Value type is [number](/reference/configuration-file-structure.md#number)
* There is no default value for this setting.

The port to listen on.


### `ssl_certificate` [plugins-inputs-lumberjack-ssl_certificate]

* This is a required setting.
* Value type is [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting.

SSL certificate to use.


### `ssl_key` [plugins-inputs-lumberjack-ssl_key]

* This is a required setting.
* Value type is [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting.

SSL key to use.


### `ssl_key_passphrase` [plugins-inputs-lumberjack-ssl_key_passphrase]

* Value type is [password](/reference/configuration-file-structure.md#password)
* There is no default value for this setting.

SSL key passphrase to use.



## Common options [plugins-inputs-lumberjack-common-options]

These configuration options are supported by all input plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`add_field`](#plugins-inputs-lumberjack-add_field) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`codec`](#plugins-inputs-lumberjack-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-inputs-lumberjack-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-inputs-lumberjack-id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`tags`](#plugins-inputs-lumberjack-tags) | [array](/reference/configuration-file-structure.md#array) | No |
| [`type`](#plugins-inputs-lumberjack-type) | [string](/reference/configuration-file-structure.md#string) | No |

### `add_field` [plugins-inputs-lumberjack-add_field]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

Add a field to an event


### `codec` [plugins-inputs-lumberjack-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for input data. Input codecs are a convenient method for decoding your data before it enters the input, without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-inputs-lumberjack-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance by default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-inputs-lumberjack-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type, for example, if you have 2 lumberjack inputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
input {
  lumberjack {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::



### `tags` [plugins-inputs-lumberjack-tags]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

Add any number of arbitrary tags to your event.

This can help with processing later.


### `type` [plugins-inputs-lumberjack-type]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a `type` field to all events handled by this input.

Types are used mainly for filter activation.

The type is stored as part of the event itself, so you can also use the type to search for it in Kibana.

If you try to set a type on an event that already has one (for example when you send an event from a shipper to an indexer) then a new input will not override the existing type. A type set at the shipper stays with that event for its life even when sent to another Logstash server.



