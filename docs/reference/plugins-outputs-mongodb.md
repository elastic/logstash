---
navigation_title: "mongodb"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-outputs-mongodb.html
---

# Mongodb output plugin [plugins-outputs-mongodb]


* Plugin version: v3.1.8
* Released on: 2025-01-02
* [Changelog](https://github.com/logstash-plugins/logstash-output-mongodb/blob/v3.1.8/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://docs/reference/output-mongodb-index.md).

## Installation [_installation_39]

For plugins not bundled by default, it is easy to install by running `bin/logstash-plugin install logstash-output-mongodb`. See [Working with plugins](/reference/working-with-plugins.md) for more details.


## Getting help [_getting_help_96]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-output-mongodb). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_96]

This output writes events to MongoDB.


## Mongodb Output Configuration Options [plugins-outputs-mongodb-options]

This plugin supports the following configuration options plus the [Common options](#plugins-outputs-mongodb-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`bulk`](#plugins-outputs-mongodb-bulk) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`bulk_interval`](#plugins-outputs-mongodb-bulk_interval) | [number](/reference/configuration-file-structure.md#number) | No |
| [`bulk_size`](#plugins-outputs-mongodb-bulk_size) | [number](/reference/configuration-file-structure.md#number) | No |
| [`collection`](#plugins-outputs-mongodb-collection) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`database`](#plugins-outputs-mongodb-database) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`generateId`](#plugins-outputs-mongodb-generateId) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`isodate`](#plugins-outputs-mongodb-isodate) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`retry_delay`](#plugins-outputs-mongodb-retry_delay) | [number](/reference/configuration-file-structure.md#number) | No |
| [`uri`](#plugins-outputs-mongodb-uri) | [string](/reference/configuration-file-structure.md#string) | Yes |

Also see [Common options](#plugins-outputs-mongodb-common-options) for a list of options supported by all output plugins.

 

### `bulk` [plugins-outputs-mongodb-bulk]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Bulk insert flag, set to true to allow bulk insertion, else it will insert events one by one.


### `bulk_interval` [plugins-outputs-mongodb-bulk_interval]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `2`

Bulk interval, Used to insert events periodically if the "bulk" flag is activated.


### `bulk_size` [plugins-outputs-mongodb-bulk_size]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `900`

Bulk events number, if the number of events to insert into a collection raise that limit, it will be bulk inserted whatever the bulk interval value (mongodb hard limit is 1000).


### `collection` [plugins-outputs-mongodb-collection]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The collection to use. This value can use `%{{foo}}` values to dynamically select a collection based on data in the event.


### `database` [plugins-outputs-mongodb-database]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The database to use.


### `generateId` [plugins-outputs-mongodb-generateId]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

If true, an "_id" field will be added to the document before insertion. The "_id" field will use the timestamp of the event and overwrite an existing "_id" field in the event.


### `isodate` [plugins-outputs-mongodb-isodate]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

If true, store the @timestamp field in MongoDB as an ISODate type instead of an ISO8601 string.  For more information about this, see [http://www.mongodb.org/display/DOCS/Dates](http://www.mongodb.org/display/DOCS/Dates).


### `retry_delay` [plugins-outputs-mongodb-retry_delay]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `3`

The number of seconds to wait after failure before retrying.


### `uri` [plugins-outputs-mongodb-uri]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

A MongoDB URI to connect to. See [http://docs.mongodb.org/manual/reference/connection-string/](http://docs.mongodb.org/manual/reference/connection-string/).



## Common options [plugins-outputs-mongodb-common-options]

These configuration options are supported by all output plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`codec`](#plugins-outputs-mongodb-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-outputs-mongodb-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-outputs-mongodb-id) | [string](/reference/configuration-file-structure.md#string) | No |

### `codec` [plugins-outputs-mongodb-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for output data. Output codecs are a convenient method for encoding your data before it leaves the output without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-outputs-mongodb-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance. By default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-outputs-mongodb-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type. For example, if you have 2 mongodb outputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
output {
  mongodb {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::




