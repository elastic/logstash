---
navigation_title: "influxdb"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-outputs-influxdb.html
---

# Influxdb output plugin [plugins-outputs-influxdb]


* Plugin version: v5.0.6
* Released on: 2021-06-07
* [Changelog](https://github.com/logstash-plugins/logstash-output-influxdb/blob/v5.0.6/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://reference/output-influxdb-index.md).

## Installation [_installation_33]

For plugins not bundled by default, it is easy to install by running `bin/logstash-plugin install logstash-output-influxdb`. See [Working with plugins](/reference/working-with-plugins.md) for more details.


## Getting help [_getting_help_86]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-output-influxdb). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_86]

This output lets you output Metrics to InfluxDB (>= 0.9.0-rc31)

The configuration here attempts to be as friendly as possible and minimize the need for multiple definitions to write to multiple measurements and still be efficient

the InfluxDB API let’s you do some semblance of bulk operation per http call but each call is database-specific

You can learn more at [InfluxDB homepage](http://influxdb.com)


## Influxdb Output Configuration Options [plugins-outputs-influxdb-options]

This plugin supports the following configuration options plus the [Common options](#plugins-outputs-influxdb-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`allow_time_override`](#plugins-outputs-influxdb-allow_time_override) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`coerce_values`](#plugins-outputs-influxdb-coerce_values) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`data_points`](#plugins-outputs-influxdb-data_points) | [hash](/reference/configuration-file-structure.md#hash) | Yes |
| [`db`](#plugins-outputs-influxdb-db) | [string](/reference/configuration-file-structure.md#string) | No |
| [`exclude_fields`](#plugins-outputs-influxdb-exclude_fields) | [array](/reference/configuration-file-structure.md#array) | No |
| [`flush_size`](#plugins-outputs-influxdb-flush_size) | [number](/reference/configuration-file-structure.md#number) | No |
| [`host`](#plugins-outputs-influxdb-host) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`idle_flush_time`](#plugins-outputs-influxdb-idle_flush_time) | [number](/reference/configuration-file-structure.md#number) | No |
| [`initial_delay`](#plugins-outputs-influxdb-initial_delay) | [number](/reference/configuration-file-structure.md#number) | No |
| [`max_retries`](#plugins-outputs-influxdb-max_retries) | [number](/reference/configuration-file-structure.md#number) | No |
| [`measurement`](#plugins-outputs-influxdb-measurement) | [string](/reference/configuration-file-structure.md#string) | No |
| [`password`](#plugins-outputs-influxdb-password) | [password](/reference/configuration-file-structure.md#password) | No |
| [`port`](#plugins-outputs-influxdb-port) | [number](/reference/configuration-file-structure.md#number) | No |
| [`retention_policy`](#plugins-outputs-influxdb-retention_policy) | [string](/reference/configuration-file-structure.md#string) | No |
| [`send_as_tags`](#plugins-outputs-influxdb-send_as_tags) | [array](/reference/configuration-file-structure.md#array) | No |
| [`ssl`](#plugins-outputs-influxdb-ssl) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`time_precision`](#plugins-outputs-influxdb-time_precision) | [string](/reference/configuration-file-structure.md#string), one of `["n", "u", "ms", "s", "m", "h"]` | No |
| [`use_event_fields_for_data_points`](#plugins-outputs-influxdb-use_event_fields_for_data_points) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`user`](#plugins-outputs-influxdb-user) | [string](/reference/configuration-file-structure.md#string) | No |

Also see [Common options](#plugins-outputs-influxdb-common-options) for a list of options supported by all output plugins.

 

### `allow_time_override` [plugins-outputs-influxdb-allow_time_override]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Allow the override of the `time` column in the event?

By default any column with a name of `time` will be ignored and the time will be determined by the value of `@timestamp`.

Setting this to `true` allows you to explicitly set the `time` column yourself

Note: **`time` must be an epoch value in either seconds, milliseconds or microseconds**


### `coerce_values` [plugins-outputs-influxdb-coerce_values]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

Allow value coercion

this will attempt to convert data point values to the appropriate type before posting otherwise sprintf-filtered numeric values could get sent as strings format is `{'column_name' => 'datatype'}`

currently supported datatypes are `integer` and `float`


### `data_points` [plugins-outputs-influxdb-data_points]

* This is a required setting.
* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

Hash of key/value pairs representing data points to send to the named database Example: `{'column1' => 'value1', 'column2' => 'value2'}`

Events for the same measurement will be batched together where possible Both keys and values support sprintf formatting


### `db` [plugins-outputs-influxdb-db]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"statistics"`

The database to write - supports sprintf formatting


### `exclude_fields` [plugins-outputs-influxdb-exclude_fields]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `["@timestamp", "@version", "sequence", "message", "type"]`

An array containing the names of fields from the event to exclude from the data points

Events, in general, contain keys "@version" and "@timestamp". Other plugins may add others that you’ll want to exclude (such as "command" from the exec plugin).

This only applies when use_event_fields_for_data_points is true.


### `flush_size` [plugins-outputs-influxdb-flush_size]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `100`

This setting controls how many events will be buffered before sending a batch of events. Note that these are only batched for the same measurement


### `host` [plugins-outputs-influxdb-host]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The hostname or IP address to reach your InfluxDB instance


### `idle_flush_time` [plugins-outputs-influxdb-idle_flush_time]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `1`

The amount of time since last flush before a flush is forced.

This setting helps ensure slow event rates don’t get stuck in Logstash. For example, if your `flush_size` is 100, and you have received 10 events, and it has been more than `idle_flush_time` seconds since the last flush, logstash will flush those 10 events automatically.

This helps keep both fast and slow log streams moving along in near-real-time.


### `initial_delay` [plugins-outputs-influxdb-initial_delay]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `1`

The amount of time in seconds to delay the initial retry on connection failure.

The delay will increase exponentially for each retry attempt (up to max_retries).


### `max_retries` [plugins-outputs-influxdb-max_retries]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `3`

The number of time to retry recoverable errors before dropping the events.

A value of -1 will cause the plugin to retry indefinately. A value of 0 will cause the plugin to never retry. Otherwise it will retry up to the specified number of times.


### `measurement` [plugins-outputs-influxdb-measurement]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"logstash"`

Measurement name - supports sprintf formatting


### `password` [plugins-outputs-influxdb-password]

* Value type is [password](/reference/configuration-file-structure.md#password)
* Default value is `nil`

The password for the user who access to the named database


### `port` [plugins-outputs-influxdb-port]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `8086`

The port for InfluxDB


### `retention_policy` [plugins-outputs-influxdb-retention_policy]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"autogen"`

The retention policy to use


### `send_as_tags` [plugins-outputs-influxdb-send_as_tags]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `["host"]`

An array containing the names of fields to send to Influxdb as tags instead of fields. Influxdb 0.9 convention is that values that do not change every request should be considered metadata and given as tags. Tags are only sent when present in `data_points` or if `use_event_fields_for_data_points` is `true`.


### `ssl` [plugins-outputs-influxdb-ssl]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Enable SSL/TLS secured communication to InfluxDB


### `time_precision` [plugins-outputs-influxdb-time_precision]

* Value can be any of: `n`, `u`, `ms`, `s`, `m`, `h`
* Default value is `"ms"`

Set the level of precision of `time`

only useful when overriding the time value


### `use_event_fields_for_data_points` [plugins-outputs-influxdb-use_event_fields_for_data_points]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Automatically use fields from the event as the data points sent to Influxdb


### `user` [plugins-outputs-influxdb-user]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `nil`

The user who has access to the named database



## Common options [plugins-outputs-influxdb-common-options]

These configuration options are supported by all output plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`codec`](#plugins-outputs-influxdb-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-outputs-influxdb-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-outputs-influxdb-id) | [string](/reference/configuration-file-structure.md#string) | No |

### `codec` [plugins-outputs-influxdb-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for output data. Output codecs are a convenient method for encoding your data before it leaves the output without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-outputs-influxdb-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance. By default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-outputs-influxdb-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type. For example, if you have 2 influxdb outputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
output {
  influxdb {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::
