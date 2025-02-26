---
navigation_title: "xmpp"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-inputs-xmpp.html
---

# Xmpp input plugin [plugins-inputs-xmpp]


* Plugin version: v3.1.7
* Released on: 2018-04-06
* [Changelog](https://github.com/logstash-plugins/logstash-input-xmpp/blob/v3.1.7/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://docs/reference/input-xmpp-index.md).

## Installation [_installation_20]

For plugins not bundled by default, it is easy to install by running `bin/logstash-plugin install logstash-input-xmpp`. See [Working with plugins](/reference/working-with-plugins.md) for more details.


## Getting help [_getting_help_64]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-input-xmpp). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_64]

This input allows you to receive events over XMPP/Jabber.

This plugin can be used for accepting events from humans or applications XMPP, or you can use it for PubSub or general message passing for logstash to logstash.


## Xmpp Input Configuration Options [plugins-inputs-xmpp-options]

This plugin supports the following configuration options plus the [Common options](#plugins-inputs-xmpp-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`host`](#plugins-inputs-xmpp-host) | [string](/reference/configuration-file-structure.md#string) | No |
| [`password`](#plugins-inputs-xmpp-password) | [password](/reference/configuration-file-structure.md#password) | Yes |
| [`rooms`](#plugins-inputs-xmpp-rooms) | [array](/reference/configuration-file-structure.md#array) | No |
| [`user`](#plugins-inputs-xmpp-user) | [string](/reference/configuration-file-structure.md#string) | Yes |

Also see [Common options](#plugins-inputs-xmpp-common-options) for a list of options supported by all input plugins.

 

### `host` [plugins-inputs-xmpp-host]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The xmpp server to connect to. This is optional. If you omit this setting, the host on the user/identity is used. (`foo.com` for `user@foo.com`)


### `password` [plugins-inputs-xmpp-password]

* This is a required setting.
* Value type is [password](/reference/configuration-file-structure.md#password)
* There is no default value for this setting.

The xmpp password for the user/identity.


### `rooms` [plugins-inputs-xmpp-rooms]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

if muc/multi-user-chat required, give the name of the room that you want to join: `room@conference.domain/nick`


### `user` [plugins-inputs-xmpp-user]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The user or resource ID, like `foo@example.com`.



## Common options [plugins-inputs-xmpp-common-options]

These configuration options are supported by all input plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`add_field`](#plugins-inputs-xmpp-add_field) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`codec`](#plugins-inputs-xmpp-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-inputs-xmpp-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-inputs-xmpp-id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`tags`](#plugins-inputs-xmpp-tags) | [array](/reference/configuration-file-structure.md#array) | No |
| [`type`](#plugins-inputs-xmpp-type) | [string](/reference/configuration-file-structure.md#string) | No |

### `add_field` [plugins-inputs-xmpp-add_field]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

Add a field to an event


### `codec` [plugins-inputs-xmpp-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for input data. Input codecs are a convenient method for decoding your data before it enters the input, without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-inputs-xmpp-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance by default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-inputs-xmpp-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type, for example, if you have 2 xmpp inputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
input {
  xmpp {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::



### `tags` [plugins-inputs-xmpp-tags]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

Add any number of arbitrary tags to your event.

This can help with processing later.


### `type` [plugins-inputs-xmpp-type]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a `type` field to all events handled by this input.

Types are used mainly for filter activation.

The type is stored as part of the event itself, so you can also use the type to search for it in Kibana.

If you try to set a type on an event that already has one (for example when you send an event from a shipper to an indexer) then a new input will not override the existing type. A type set at the shipper stays with that event for its life even when sent to another Logstash server.



