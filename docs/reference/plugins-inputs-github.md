---
navigation_title: "github"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-inputs-github.html
---

# Github input plugin [plugins-inputs-github]


* Plugin version: v3.0.11
* Released on: 2023-05-30
* [Changelog](https://github.com/logstash-plugins/logstash-input-github/blob/v3.0.11/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://reference/input-github-index.md).

## Installation [_installation]

For plugins not bundled by default, it is easy to install by running `bin/logstash-plugin install logstash-input-github`. See [Working with plugins](/reference/working-with-plugins.md) for more details.


## Getting help [_getting_help_21]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-input-github). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_22]

Read events from github webhooks


## Github Input Configuration Options [plugins-inputs-github-options]

This plugin supports the following configuration options plus the [Common options](#plugins-inputs-github-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`drop_invalid`](#plugins-inputs-github-drop_invalid) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`ip`](#plugins-inputs-github-ip) | [string](/reference/configuration-file-structure.md#string) | No |
| [`port`](#plugins-inputs-github-port) | [number](/reference/configuration-file-structure.md#number) | Yes |
| [`secret_token`](#plugins-inputs-github-secret_token) | [password](/reference/configuration-file-structure.md#password) | No |

Also see [Common options](#plugins-inputs-github-common-options) for a list of options supported by all input plugins.

 

### `drop_invalid` [plugins-inputs-github-drop_invalid]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

If Secret is defined, we drop the events that don’t match. Otherwise, we’ll just add an invalid tag


### `ip` [plugins-inputs-github-ip]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"0.0.0.0"`

The ip to listen on


### `port` [plugins-inputs-github-port]

* This is a required setting.
* Value type is [number](/reference/configuration-file-structure.md#number)
* There is no default value for this setting.

The port to listen on


### `secret_token` [plugins-inputs-github-secret_token]

* Value type is [password](/reference/configuration-file-structure.md#password)
* There is no default value for this setting.

Your GitHub Secret Token for the webhook



## Common options [plugins-inputs-github-common-options]

These configuration options are supported by all input plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`add_field`](#plugins-inputs-github-add_field) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`codec`](#plugins-inputs-github-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-inputs-github-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-inputs-github-id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`tags`](#plugins-inputs-github-tags) | [array](/reference/configuration-file-structure.md#array) | No |
| [`type`](#plugins-inputs-github-type) | [string](/reference/configuration-file-structure.md#string) | No |

### `add_field` [plugins-inputs-github-add_field]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

Add a field to an event


### `codec` [plugins-inputs-github-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for input data. Input codecs are a convenient method for decoding your data before it enters the input, without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-inputs-github-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance by default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-inputs-github-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type, for example, if you have 2 github inputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
input {
  github {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::



### `tags` [plugins-inputs-github-tags]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

Add any number of arbitrary tags to your event.

This can help with processing later.


### `type` [plugins-inputs-github-type]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a `type` field to all events handled by this input.

Types are used mainly for filter activation.

The type is stored as part of the event itself, so you can also use the type to search for it in Kibana.

If you try to set a type on an event that already has one (for example when you send an event from a shipper to an indexer) then a new input will not override the existing type. A type set at the shipper stays with that event for its life even when sent to another Logstash server.



