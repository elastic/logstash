---
navigation_title: "websocket"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-outputs-websocket.html
---

# Websocket output plugin [plugins-outputs-websocket]


* Plugin version: v3.1.0
* Released on: 2024-01-11
* [Changelog](https://github.com/logstash-plugins/logstash-output-websocket/blob/v3.1.0/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://docs/reference/output-websocket-index.md).

## Installation [_installation_51]

For plugins not bundled by default, it is easy to install by running `bin/logstash-plugin install logstash-output-websocket`. See [Working with plugins](/reference/working-with-plugins.md) for more details.


## Getting help [_getting_help_120]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-output-websocket). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_120]

This output runs a websocket server and publishes any messages to all connected websocket clients.

You can connect to it with ws://<host\>:<port\>/

If no clients are connected, any messages received are ignored.


## Websocket Output Configuration Options [plugins-outputs-websocket-options]

This plugin supports the following configuration options plus the [Common options](#plugins-outputs-websocket-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`host`](#plugins-outputs-websocket-host) | [string](/reference/configuration-file-structure.md#string) | No |
| [`port`](#plugins-outputs-websocket-port) | [number](/reference/configuration-file-structure.md#number) | No |

Also see [Common options](#plugins-outputs-websocket-common-options) for a list of options supported by all output plugins.

 

### `host` [plugins-outputs-websocket-host]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"0.0.0.0"`

The address to serve websocket data from


### `port` [plugins-outputs-websocket-port]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `3232`

The port to serve websocket data from



## Common options [plugins-outputs-websocket-common-options]

These configuration options are supported by all output plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`codec`](#plugins-outputs-websocket-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-outputs-websocket-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-outputs-websocket-id) | [string](/reference/configuration-file-structure.md#string) | No |

### `codec` [plugins-outputs-websocket-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for output data. Output codecs are a convenient method for encoding your data before it leaves the output without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-outputs-websocket-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance. By default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-outputs-websocket-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type. For example, if you have 2 websocket outputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
output {
  websocket {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::




