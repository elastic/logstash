---
navigation_title: "meetup"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-inputs-meetup.html
---

# Meetup input plugin [plugins-inputs-meetup]


* Plugin version: v3.1.1
* Released on: 2018-04-06
* [Changelog](https://github.com/logstash-plugins/logstash-input-meetup/blob/v3.1.1/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://reference/input-meetup-index.md).

## Installation [_installation_9]

For plugins not bundled by default, it is easy to install by running `bin/logstash-plugin install logstash-input-meetup`. See [Working with plugins](/reference/working-with-plugins.md) for more details.


## Getting help [_getting_help_40]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-input-meetup). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_40]

Periodically query meetup.com regarding updates on events for the given Meetup key.


## Meetup Input Configuration Options [plugins-inputs-meetup-options]

This plugin supports the following configuration options plus the [Common options](#plugins-inputs-meetup-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`eventstatus`](#plugins-inputs-meetup-eventstatus) | [string](/reference/configuration-file-structure.md#string) | No |
| [`groupid`](#plugins-inputs-meetup-groupid) | [string](/reference/configuration-file-structure.md#string) | No |
| [`interval`](#plugins-inputs-meetup-interval) | [number](/reference/configuration-file-structure.md#number) | Yes |
| [`meetupkey`](#plugins-inputs-meetup-meetupkey) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`urlname`](#plugins-inputs-meetup-urlname) | [string](/reference/configuration-file-structure.md#string) | No |
| [`venueid`](#plugins-inputs-meetup-venueid) | [string](/reference/configuration-file-structure.md#string) | No |
| [`text`](#plugins-inputs-meetup-text) | [string](/reference/configuration-file-structure.md#string) | No |

Also see [Common options](#plugins-inputs-meetup-common-options) for a list of options supported by all input plugins.

 

### `eventstatus` [plugins-inputs-meetup-eventstatus]

* Value type is [string](/reference/configuration-file-structure.md#string).
* Default value is `"upcoming,past"`.

Event Status can be one of `"upcoming"`, `"past"`, or `"upcoming,past"`. Default is `"upcoming,past"`.


### `groupid` [plugins-inputs-meetup-groupid]

* Value type is [string](/reference/configuration-file-structure.md#string).
* There is no default value for this setting.

The Group ID, multiple may be specified seperated by commas. Must have one of `urlname`, `venueid`, `groupid`, `text`.


### `interval` [plugins-inputs-meetup-interval]

* This is a required setting.
* Value type is [number](/reference/configuration-file-structure.md#number).
* There is no default value for this setting.

Interval to run the command. Value is in minutes.


### `meetupkey` [plugins-inputs-meetup-meetupkey]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string).
* There is no default value for this setting.

Meetup Key, aka personal token.


### `urlname` [plugins-inputs-meetup-urlname]

* Value type is [string](/reference/configuration-file-structure.md#string).
* There is no default value for this setting.

URLName - the URL name ie `ElasticSearch-Oklahoma-City`. Must have one of urlname, venue_id, group_id, `text`.


### `venueid` [plugins-inputs-meetup-venueid]

* Value type is [string](/reference/configuration-file-structure.md#string).
* There is no default value for this setting.

The venue ID Must have one of `urlname`, `venue_id`, `group_id`, `text`.


### `text` [plugins-inputs-meetup-text]

* Value type is [string](/reference/configuration-file-structure.md#string).
* There is no default value for this setting.

A text string to search meetup events by. Must have one of `urlname`, `venue_id`, `group_id`, `text`.



## Common options [plugins-inputs-meetup-common-options]

These configuration options are supported by all input plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`add_field`](#plugins-inputs-meetup-add_field) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`codec`](#plugins-inputs-meetup-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-inputs-meetup-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-inputs-meetup-id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`tags`](#plugins-inputs-meetup-tags) | [array](/reference/configuration-file-structure.md#array) | No |
| [`type`](#plugins-inputs-meetup-type) | [string](/reference/configuration-file-structure.md#string) | No |

### `add_field` [plugins-inputs-meetup-add_field]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

Add a field to an event


### `codec` [plugins-inputs-meetup-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for input data. Input codecs are a convenient method for decoding your data before it enters the input, without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-inputs-meetup-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance by default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-inputs-meetup-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type, for example, if you have 2 meetup inputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
input {
  meetup {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::



### `tags` [plugins-inputs-meetup-tags]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

Add any number of arbitrary tags to your event.

This can help with processing later.


### `type` [plugins-inputs-meetup-type]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a `type` field to all events handled by this input.

Types are used mainly for filter activation.

The type is stored as part of the event itself, so you can also use the type to search for it in Kibana.

If you try to set a type on an event that already has one (for example when you send an event from a shipper to an indexer) then a new input will not override the existing type. A type set at the shipper stays with that event for its life even when sent to another Logstash server.



