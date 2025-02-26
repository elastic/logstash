---
navigation_title: "opentsdb"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-outputs-opentsdb.html
---

# Opentsdb output plugin [plugins-outputs-opentsdb]


* Plugin version: v3.1.5
* Released on: 2018-04-06
* [Changelog](https://github.com/logstash-plugins/logstash-output-opentsdb/blob/v3.1.5/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://docs/reference/output-opentsdb-index.md).

## Installation [_installation_41]

For plugins not bundled by default, it is easy to install by running `bin/logstash-plugin install logstash-output-opentsdb`. See [Working with plugins](/reference/working-with-plugins.md) for more details.


## Getting help [_getting_help_99]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-output-opentsdb). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_99]

This output allows you to pull metrics from your logs and ship them to opentsdb. Opentsdb is an open source tool for storing and graphing metrics.


## Opentsdb Output Configuration Options [plugins-outputs-opentsdb-options]

This plugin supports the following configuration options plus the [Common options](#plugins-outputs-opentsdb-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`host`](#plugins-outputs-opentsdb-host) | [string](/reference/configuration-file-structure.md#string) | No |
| [`metrics`](#plugins-outputs-opentsdb-metrics) | [array](/reference/configuration-file-structure.md#array) | Yes |
| [`port`](#plugins-outputs-opentsdb-port) | [number](/reference/configuration-file-structure.md#number) | No |

Also see [Common options](#plugins-outputs-opentsdb-common-options) for a list of options supported by all output plugins.

 

### `host` [plugins-outputs-opentsdb-host]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"localhost"`

The address of the opentsdb server.


### `metrics` [plugins-outputs-opentsdb-metrics]

* This is a required setting.
* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

The metric(s) to use. This supports dynamic strings like `%{{source_host}}` for metric names and also for values. This is an array field with key of the metric name, value of the metric value, and multiple tag,values . Example:

```ruby
    [
      "%{host}/uptime",
      %{uptime_1m} " ,
      "hostname" ,
      "%{host}
      "anotherhostname" ,
      "%{host}
    ]
```

The value will be coerced to a floating point value. Values which cannot be coerced will zero (0)


### `port` [plugins-outputs-opentsdb-port]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `4242`

The port to connect on your graphite server.



## Common options [plugins-outputs-opentsdb-common-options]

These configuration options are supported by all output plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`codec`](#plugins-outputs-opentsdb-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-outputs-opentsdb-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-outputs-opentsdb-id) | [string](/reference/configuration-file-structure.md#string) | No |

### `codec` [plugins-outputs-opentsdb-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for output data. Output codecs are a convenient method for encoding your data before it leaves the output without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-outputs-opentsdb-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance. By default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-outputs-opentsdb-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type. For example, if you have 2 opentsdb outputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
output {
  opentsdb {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::




