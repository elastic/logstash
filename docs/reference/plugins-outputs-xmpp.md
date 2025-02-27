---
navigation_title: "xmpp"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-outputs-xmpp.html
---

# Xmpp output plugin [plugins-outputs-xmpp]


* Plugin version: v3.0.8
* Released on: 2018-04-06
* [Changelog](https://github.com/logstash-plugins/logstash-output-xmpp/blob/v3.0.8/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://docs/reference/output-xmpp-index.md).

## Installation [_installation_52]

For plugins not bundled by default, it is easy to install by running `bin/logstash-plugin install logstash-output-xmpp`. See [Working with plugins](/reference/working-with-plugins.md) for more details.


## Getting help [_getting_help_121]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-output-xmpp). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_121]

This output allows you ship events over XMPP/Jabber.

This plugin can be used for posting events to humans over XMPP, or you can use it for PubSub or general message passing for logstash to logstash.


## Xmpp Output Configuration Options [plugins-outputs-xmpp-options]

This plugin supports the following configuration options plus the [Common options](#plugins-outputs-xmpp-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`host`](#plugins-outputs-xmpp-host) | [string](/reference/configuration-file-structure.md#string) | No |
| [`message`](#plugins-outputs-xmpp-message) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`password`](#plugins-outputs-xmpp-password) | [password](/reference/configuration-file-structure.md#password) | Yes |
| [`rooms`](#plugins-outputs-xmpp-rooms) | [array](/reference/configuration-file-structure.md#array) | No |
| [`user`](#plugins-outputs-xmpp-user) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`users`](#plugins-outputs-xmpp-users) | [array](/reference/configuration-file-structure.md#array) | No |

Also see [Common options](#plugins-outputs-xmpp-common-options) for a list of options supported by all output plugins.

 

### `host` [plugins-outputs-xmpp-host]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The xmpp server to connect to. This is optional. If you omit this setting, the host on the user/identity is used. (foo.com for `user@foo.com`)


### `message` [plugins-outputs-xmpp-message]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The message to send. This supports dynamic strings like `%{{host}}`


### `password` [plugins-outputs-xmpp-password]

* This is a required setting.
* Value type is [password](/reference/configuration-file-structure.md#password)
* There is no default value for this setting.

The xmpp password for the user/identity.


### `rooms` [plugins-outputs-xmpp-rooms]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

if muc/multi-user-chat required, give the name of the room that you want to join: room@conference.domain/nick


### `user` [plugins-outputs-xmpp-user]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The user or resource ID, like `foo@example.com`.


### `users` [plugins-outputs-xmpp-users]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

The users to send messages to



## Common options [plugins-outputs-xmpp-common-options]

These configuration options are supported by all output plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`codec`](#plugins-outputs-xmpp-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-outputs-xmpp-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-outputs-xmpp-id) | [string](/reference/configuration-file-structure.md#string) | No |

### `codec` [plugins-outputs-xmpp-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for output data. Output codecs are a convenient method for encoding your data before it leaves the output without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-outputs-xmpp-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance. By default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-outputs-xmpp-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type. For example, if you have 2 xmpp outputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
output {
  xmpp {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::




