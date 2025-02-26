---
navigation_title: "statsd"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-outputs-statsd.html
---

# Statsd output plugin [plugins-outputs-statsd]


* Plugin version: v3.2.0
* Released on: 2018-06-05
* [Changelog](https://github.com/logstash-plugins/logstash-output-statsd/blob/v3.2.0/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://docs/reference/output-statsd-index.md).

## Installation [_installation_47]

For plugins not bundled by default, it is easy to install by running `bin/logstash-plugin install logstash-output-statsd`. See [Working with plugins](/reference/working-with-plugins.md) for more details.


## Getting help [_getting_help_112]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-output-statsd). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_112]

statsd is a network daemon for aggregating statistics, such as counters and timers, and shipping over UDP to backend services, such as Graphite or Datadog. The general idea is that you send metrics to statsd and every few seconds it will emit the aggregated values to the backend. Example aggregates are sums, average and maximum values, their standard deviation, etc. This plugin makes it easy to send such metrics based on data in Logstash events.

You can learn about statsd here:

* [Etsy blog post announcing statsd](https://codeascraft.com/2011/02/15/measure-anything-measure-everything/)
* [statsd on github](https://github.com/etsy/statsd)

Typical examples of how this can be used with Logstash include counting HTTP hits by response code, summing the total number of bytes of traffic served, and tracking the 50th and 95th percentile of the processing time of requests.

Each metric emitted to statsd has a dot-separated path, a type, and a value. The metric path is built from the `namespace` and `sender` options together with the metric name that’s picked up depending on the type of metric. All in all, the metric path will follow this pattern:

```
namespace.sender.metric
```
With regards to this plugin, the default namespace is "logstash", the default sender is the `host` field, and the metric name depends on what is set as the metric name in the `increment`, `decrement`, `timing`, `count`, `set` or `gauge` options. In metric paths, colons (":"), pipes ("|") and at signs ("@") are reserved and will be replaced by underscores ("_").

Example:

```ruby
output {
  statsd {
    host => "statsd.example.org"
    count => {
      "http.bytes" => "%{bytes}"
    }
  }
}
```

If run on a host named hal9000 the configuration above will send the following metric to statsd if the current event has 123 in its `bytes` field:

```
logstash.hal9000.http.bytes:123|c
```

## Statsd Output Configuration Options [plugins-outputs-statsd-options]

This plugin supports the following configuration options plus the [Common options](#plugins-outputs-statsd-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`count`](#plugins-outputs-statsd-count) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`decrement`](#plugins-outputs-statsd-decrement) | [array](/reference/configuration-file-structure.md#array) | No |
| [`gauge`](#plugins-outputs-statsd-gauge) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`host`](#plugins-outputs-statsd-host) | [string](/reference/configuration-file-structure.md#string) | No |
| [`increment`](#plugins-outputs-statsd-increment) | [array](/reference/configuration-file-structure.md#array) | No |
| [`namespace`](#plugins-outputs-statsd-namespace) | [string](/reference/configuration-file-structure.md#string) | No |
| [`port`](#plugins-outputs-statsd-port) | [number](/reference/configuration-file-structure.md#number) | No |
| [`sample_rate`](#plugins-outputs-statsd-sample_rate) | [number](/reference/configuration-file-structure.md#number) | No |
| [`sender`](#plugins-outputs-statsd-sender) | [string](/reference/configuration-file-structure.md#string) | No |
| [`set`](#plugins-outputs-statsd-set) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`timing`](#plugins-outputs-statsd-timing) | [hash](/reference/configuration-file-structure.md#hash) | No |

Also see [Common options](#plugins-outputs-statsd-common-options) for a list of options supported by all output plugins.

 

### `count` [plugins-outputs-statsd-count]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

A count metric. `metric_name => count` as hash. `%{{fieldname}}` substitutions are allowed in the metric names.


### `decrement` [plugins-outputs-statsd-decrement]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

A decrement metric. Metric names as array. `%{{fieldname}}` substitutions are allowed in the metric names.


### `gauge` [plugins-outputs-statsd-gauge]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

A gauge metric. `metric_name => gauge` as hash. `%{{fieldname}}` substitutions are allowed in the metric names.


### `host` [plugins-outputs-statsd-host]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"localhost"`

The hostname or IP address of the statsd server.


### `increment` [plugins-outputs-statsd-increment]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

An increment metric. Metric names as array. `%{{fieldname}}` substitutions are allowed in the metric names.


### `namespace` [plugins-outputs-statsd-namespace]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"logstash"`

The statsd namespace to use for this metric. `%{{fieldname}}` substitutions are allowed.


### `port` [plugins-outputs-statsd-port]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `8125`

The port to connect to on your statsd server.


### `protocol` [plugins-outputs-statsd-protocol]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"udp"`

The protocol to connect to on your statsd server.


### `sample_rate` [plugins-outputs-statsd-sample_rate]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `1`

The sample rate for the metric.


### `sender` [plugins-outputs-statsd-sender]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `%{{host}}`

The name of the sender. Dots will be replaced with underscores. `%{{fieldname}}` substitutions are allowed.


### `set` [plugins-outputs-statsd-set]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

A set metric. `metric_name => "string"` to append as hash. `%{{fieldname}}` substitutions are allowed in the metric names.


### `timing` [plugins-outputs-statsd-timing]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

A timing metric. `metric_name => duration` as hash. `%{{fieldname}}` substitutions are allowed in the metric names.



## Common options [plugins-outputs-statsd-common-options]

These configuration options are supported by all output plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`codec`](#plugins-outputs-statsd-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-outputs-statsd-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-outputs-statsd-id) | [string](/reference/configuration-file-structure.md#string) | No |

### `codec` [plugins-outputs-statsd-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for output data. Output codecs are a convenient method for encoding your data before it leaves the output without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-outputs-statsd-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance. By default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-outputs-statsd-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type. For example, if you have 2 statsd outputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
output {
  statsd {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::




