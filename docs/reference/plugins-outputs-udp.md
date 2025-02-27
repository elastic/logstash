---
navigation_title: "udp"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-outputs-udp.html
---

# Udp output plugin [plugins-outputs-udp]


* Plugin version: v3.2.0
* Released on: 2021-07-14
* [Changelog](https://github.com/logstash-plugins/logstash-output-udp/blob/v3.2.0/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://docs/reference/output-udp-index.md).

## Getting help [_getting_help_118]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-output-udp). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_118]

Send events over UDP

Keep in mind that UDP does not provide delivery or duplicate protection guarantees. Even when this plugin succeeds at writing to the UDP socket, there is no guarantee that the recipient will receive exactly one copy of the event.

When this plugin fails to write to the UDP socket, by default the event will be dropped and the error message will be logged. The [`retry_count`](#plugins-outputs-udp-retry_count) option in conjunction with the [`retry_backoff_ms`](#plugins-outputs-udp-retry_backoff_ms) option can be used to retry a failed write for a number of times before dropping the event.


## Udp Output Configuration Options [plugins-outputs-udp-options]

This plugin supports the following configuration options plus the [Common options](#plugins-outputs-udp-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`host`](#plugins-outputs-udp-host) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`port`](#plugins-outputs-udp-port) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`retry_count`](#plugins-outputs-udp-retry_count) | [number](/reference/configuration-file-structure.md#number) | No |
| [`retry_backoff_ms`](#plugins-outputs-udp-retry_backoff_ms) | [number](/reference/configuration-file-structure.md#number) | No |

Also see [Common options](#plugins-outputs-udp-common-options) for a list of options supported by all output plugins.

 

### `host` [plugins-outputs-udp-host]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The address to send messages to


### `port` [plugins-outputs-udp-port]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The port to send messages on. This can be dynamic using the `%{[target][port]}` syntax.


### `retry_count` [plugins-outputs-udp-retry_count]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `0`

The number of times to retry a failed UPD socket write


### `retry_backoff_ms` [plugins-outputs-udp-retry_backoff_ms]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `10`

The amount of time to wait in milliseconds before attempting to retry a failed UPD socket write



## Common options [plugins-outputs-udp-common-options]

These configuration options are supported by all output plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`codec`](#plugins-outputs-udp-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-outputs-udp-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-outputs-udp-id) | [string](/reference/configuration-file-structure.md#string) | No |

### `codec` [plugins-outputs-udp-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"json"`

The codec used for output data. Output codecs are a convenient method for encoding your data before it leaves the output without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-outputs-udp-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance. By default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-outputs-udp-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type. For example, if you have 2 udp outputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
output {
  udp {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::




