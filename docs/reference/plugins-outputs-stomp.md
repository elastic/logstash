---
navigation_title: "stomp"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-outputs-stomp.html
---

# Stomp output plugin [plugins-outputs-stomp]


* Plugin version: v3.0.9
* Released on: 2018-04-06
* [Changelog](https://github.com/logstash-plugins/logstash-output-stomp/blob/v3.0.9/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://reference/output-stomp-index.md).

## Installation [_installation_48]

For plugins not bundled by default, it is easy to install by running `bin/logstash-plugin install logstash-output-stomp`. See [Working with plugins](/reference/working-with-plugins.md) for more details.


## Getting help [_getting_help_114]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-output-stomp). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_114]

This output writes events using the STOMP protocol.


## Stomp Output Configuration Options [plugins-outputs-stomp-options]

This plugin supports the following configuration options plus the [Common options](#plugins-outputs-stomp-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`debug`](#plugins-outputs-stomp-debug) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`destination`](#plugins-outputs-stomp-destination) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`headers`](#plugins-outputs-stomp-headers) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`host`](#plugins-outputs-stomp-host) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`password`](#plugins-outputs-stomp-password) | [password](/reference/configuration-file-structure.md#password) | No |
| [`port`](#plugins-outputs-stomp-port) | [number](/reference/configuration-file-structure.md#number) | No |
| [`user`](#plugins-outputs-stomp-user) | [string](/reference/configuration-file-structure.md#string) | No |
| [`vhost`](#plugins-outputs-stomp-vhost) | [string](/reference/configuration-file-structure.md#string) | No |

Also see [Common options](#plugins-outputs-stomp-common-options) for a list of options supported by all output plugins.

 

### `debug` [plugins-outputs-stomp-debug]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Enable debugging output?


### `destination` [plugins-outputs-stomp-destination]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The destination to read events from. Supports string expansion, meaning `%{{foo}}` values will expand to the field value.

Example: "/topic/logstash"


### `headers` [plugins-outputs-stomp-headers]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* There is no default value for this setting.

Custom headers to send with each message. Supports string expansion, meaning `%{{foo}}` values will expand to the field value.

Example: headers ⇒ ["amq-msg-type", "text", "host", `"%{{host}}"`]


### `host` [plugins-outputs-stomp-host]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The address of the STOMP server.


### `password` [plugins-outputs-stomp-password]

* Value type is [password](/reference/configuration-file-structure.md#password)
* Default value is `""`

The password to authenticate with.


### `port` [plugins-outputs-stomp-port]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `61613`

The port to connect to on your STOMP server.


### `user` [plugins-outputs-stomp-user]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `""`

The username to authenticate with.


### `vhost` [plugins-outputs-stomp-vhost]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `nil`

The vhost to use



## Common options [plugins-outputs-stomp-common-options]

These configuration options are supported by all output plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`codec`](#plugins-outputs-stomp-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-outputs-stomp-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-outputs-stomp-id) | [string](/reference/configuration-file-structure.md#string) | No |

### `codec` [plugins-outputs-stomp-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for output data. Output codecs are a convenient method for encoding your data before it leaves the output without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-outputs-stomp-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance. By default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-outputs-stomp-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type. For example, if you have 2 stomp outputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
output {
  stomp {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::




