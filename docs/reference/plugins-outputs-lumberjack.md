---
navigation_title: "lumberjack"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-outputs-lumberjack.html
---

# Lumberjack output plugin [plugins-outputs-lumberjack]


* Plugin version: v3.1.9
* Released on: 2021-08-30
* [Changelog](https://github.com/logstash-plugins/logstash-output-lumberjack/blob/v3.1.9/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://reference/output-lumberjack-index.md).

## Getting help [_getting_help_94]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-output-lumberjack). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_94]

This output sends events using the lumberjack protocol.


## Lumberjack Output Configuration Options [plugins-outputs-lumberjack-options]

This plugin supports the following configuration options plus the [Common options](#plugins-outputs-lumberjack-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`flush_size`](#plugins-outputs-lumberjack-flush_size) | [number](/reference/configuration-file-structure.md#number) | No |
| [`hosts`](#plugins-outputs-lumberjack-hosts) | [array](/reference/configuration-file-structure.md#array) | Yes |
| [`idle_flush_time`](#plugins-outputs-lumberjack-idle_flush_time) | [number](/reference/configuration-file-structure.md#number) | No |
| [`port`](#plugins-outputs-lumberjack-port) | [number](/reference/configuration-file-structure.md#number) | Yes |
| [`ssl_certificate`](#plugins-outputs-lumberjack-ssl_certificate) | a valid filesystem path | Yes |

Also see [Common options](#plugins-outputs-lumberjack-common-options) for a list of options supported by all output plugins.

 

### `flush_size` [plugins-outputs-lumberjack-flush_size]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `1024`

To make efficient calls to the lumberjack output we are buffering events locally. if the number of events exceed the number the declared `flush_size` we will send them to the logstash server.


### `hosts` [plugins-outputs-lumberjack-hosts]

* This is a required setting.
* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

List of addresses lumberjack can send to. When the plugin needs to connect to the remote peer, it randomly selects one of the hosts.

When the plugin is registered, it opens a connection to one of the hosts. If the plugin detects a connection error, it selects a different host from the list and opens a new connection.


### `idle_flush_time` [plugins-outputs-lumberjack-idle_flush_time]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `1`

The amount of time since last flush before a flush is forced.

This setting helps ensure slow event rates don’t get stuck in Logstash. For example, if your `flush_size` is 100, and you have received 10 events, and it has been more than `idle_flush_time` seconds since the last flush, Logstash will flush those 10 events automatically.

This helps keep both fast and slow log streams moving along in near-real-time.


### `port` [plugins-outputs-lumberjack-port]

* This is a required setting.
* Value type is [number](/reference/configuration-file-structure.md#number)
* There is no default value for this setting.

the port to connect to


### `ssl_certificate` [plugins-outputs-lumberjack-ssl_certificate]

* This is a required setting.
* Value type is [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting.

ssl certificate to use



## Common options [plugins-outputs-lumberjack-common-options]

These configuration options are supported by all output plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`codec`](#plugins-outputs-lumberjack-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-outputs-lumberjack-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-outputs-lumberjack-id) | [string](/reference/configuration-file-structure.md#string) | No |

### `codec` [plugins-outputs-lumberjack-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for output data. Output codecs are a convenient method for encoding your data before it leaves the output without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-outputs-lumberjack-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance. By default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-outputs-lumberjack-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type. For example, if you have 2 lumberjack outputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
output {
  lumberjack {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::




