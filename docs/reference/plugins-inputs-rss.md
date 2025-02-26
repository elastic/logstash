---
navigation_title: "rss"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-inputs-rss.html
---

# Rss input plugin [plugins-inputs-rss]


* Plugin version: v3.0.6
* Released on: 2023-11-03
* [Changelog](https://github.com/logstash-plugins/logstash-input-rss/blob/v3.0.6/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://docs/reference/input-rss-index.md).

## Installation [_installation_12]

For plugins not bundled by default, it is easy to install by running `bin/logstash-plugin install logstash-input-rss`. See [Working with plugins](/reference/working-with-plugins.md) for more details.


## Getting help [_getting_help_46]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-input-rss). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_46]

Run command line tools and capture the whole output as an event.

Notes:

* The `@source` of this event will be the command run.
* The `@message` of this event will be the entire stdout of the command as one event.


## Rss Input Configuration Options [plugins-inputs-rss-options]

This plugin supports the following configuration options plus the [Common options](#plugins-inputs-rss-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`interval`](#plugins-inputs-rss-interval) | [number](/reference/configuration-file-structure.md#number) | Yes |
| [`url`](#plugins-inputs-rss-url) | [string](/reference/configuration-file-structure.md#string) | Yes |

Also see [Common options](#plugins-inputs-rss-common-options) for a list of options supported by all input plugins.

 

### `interval` [plugins-inputs-rss-interval]

* This is a required setting.
* Value type is [number](/reference/configuration-file-structure.md#number)
* There is no default value for this setting.

Interval to run the command. Value is in seconds.


### `url` [plugins-inputs-rss-url]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

RSS/Atom feed URL



## Common options [plugins-inputs-rss-common-options]

These configuration options are supported by all input plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`add_field`](#plugins-inputs-rss-add_field) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`codec`](#plugins-inputs-rss-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-inputs-rss-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-inputs-rss-id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`tags`](#plugins-inputs-rss-tags) | [array](/reference/configuration-file-structure.md#array) | No |
| [`type`](#plugins-inputs-rss-type) | [string](/reference/configuration-file-structure.md#string) | No |

### `add_field` [plugins-inputs-rss-add_field]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

Add a field to an event


### `codec` [plugins-inputs-rss-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for input data. Input codecs are a convenient method for decoding your data before it enters the input, without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-inputs-rss-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance by default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-inputs-rss-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type, for example, if you have 2 rss inputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
input {
  rss {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::



### `tags` [plugins-inputs-rss-tags]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

Add any number of arbitrary tags to your event.

This can help with processing later.


### `type` [plugins-inputs-rss-type]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a `type` field to all events handled by this input.

Types are used mainly for filter activation.

The type is stored as part of the event itself, so you can also use the type to search for it in Kibana.

If you try to set a type on an event that already has one (for example when you send an event from a shipper to an indexer) then a new input will not override the existing type. A type set at the shipper stays with that event for its life even when sent to another Logstash server.



