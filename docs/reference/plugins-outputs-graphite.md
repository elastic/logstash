---
navigation_title: "graphite"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-outputs-graphite.html
---

# Graphite output plugin [plugins-outputs-graphite]


* Plugin version: v3.1.6
* Released on: 2018-07-11
* [Changelog](https://github.com/logstash-plugins/logstash-output-graphite/blob/v3.1.6/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://reference/output-graphite-index.md).

## Getting help [_getting_help_83]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-output-graphite). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_83]

This output allows you to pull metrics from your logs and ship them to Graphite. Graphite is an open source tool for storing and graphing metrics.

An example use case: Some applications emit aggregated stats in the logs every 10 seconds. Using the grok filter and this output, it is possible to capture the metric values from the logs and emit them to Graphite.


## Graphite Output Configuration Options [plugins-outputs-graphite-options]

This plugin supports the following configuration options plus the [Common options](#plugins-outputs-graphite-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`exclude_metrics`](#plugins-outputs-graphite-exclude_metrics) | [array](/reference/configuration-file-structure.md#array) | No |
| [`fields_are_metrics`](#plugins-outputs-graphite-fields_are_metrics) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`host`](#plugins-outputs-graphite-host) | [string](/reference/configuration-file-structure.md#string) | No |
| [`include_metrics`](#plugins-outputs-graphite-include_metrics) | [array](/reference/configuration-file-structure.md#array) | No |
| [`metrics`](#plugins-outputs-graphite-metrics) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`metrics_format`](#plugins-outputs-graphite-metrics_format) | [string](/reference/configuration-file-structure.md#string) | No |
| [`nested_object_separator`](#plugins-outputs-graphite-nested_object_separator) | [string](/reference/configuration-file-structure.md#string) | No |
| [`port`](#plugins-outputs-graphite-port) | [number](/reference/configuration-file-structure.md#number) | No |
| [`reconnect_interval`](#plugins-outputs-graphite-reconnect_interval) | [number](/reference/configuration-file-structure.md#number) | No |
| [`resend_on_failure`](#plugins-outputs-graphite-resend_on_failure) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`timestamp_field`](#plugins-outputs-graphite-timestamp_field) | [string](/reference/configuration-file-structure.md#string) | No |

Also see [Common options](#plugins-outputs-graphite-common-options) for a list of options supported by all output plugins.

 

### `exclude_metrics` [plugins-outputs-graphite-exclude_metrics]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `["%{[^}]+}"]`

Exclude regex matched metric names, by default exclude unresolved `%{{field}}` strings.


### `fields_are_metrics` [plugins-outputs-graphite-fields_are_metrics]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

An array indicating that these event fields should be treated as metrics and will be sent verbatim to Graphite. You may use either `fields_are_metrics` or `metrics`, but not both.


### `host` [plugins-outputs-graphite-host]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"localhost"`

The hostname or IP address of the Graphite server.


### `include_metrics` [plugins-outputs-graphite-include_metrics]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[".*"]`

Include only regex matched metric names.


### `metrics` [plugins-outputs-graphite-metrics]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

The metric(s) to use. This supports dynamic strings like `%{{host}}` for metric names and also for values. This is a hash field with key being the metric name, value being the metric value. Example:

```ruby
    metrics => { "%{host}/uptime" => "%{uptime_1m}" }
```

The value will be coerced to a floating point value. Values which cannot be coerced will be set to zero (0). You may use either `metrics` or `fields_are_metrics`, but not both.


### `metrics_format` [plugins-outputs-graphite-metrics_format]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"*"`

Defines the format of the metric string. The placeholder *** will be replaced with the name of the actual metric.

```ruby
    metrics_format => "foo.bar.*.sum"
```

::::{note}
If no metrics_format is defined, the name of the metric will be used as fallback.
::::



### `nested_object_separator` [plugins-outputs-graphite-nested_object_separator]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"."`

When hashes are passed in as values they are broken out into a dotted notation For instance if you configure this plugin with # [source,ruby] metrics ⇒ "mymetrics"

and "mymetrics" is a nested hash of *{a ⇒ 1, b ⇒ { c ⇒ 2 }}* this plugin will generate two metrics: a ⇒ 1, and b.c ⇒ 2 . If you’ve specified a *metrics_format* it will respect that, but you still may want control over the separator within these nested key names. This config setting changes the separator from the *.* default.


### `port` [plugins-outputs-graphite-port]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `2003`

The port to connect to on the Graphite server.


### `reconnect_interval` [plugins-outputs-graphite-reconnect_interval]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `2`

Interval between reconnect attempts to Carbon.


### `resend_on_failure` [plugins-outputs-graphite-resend_on_failure]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Should metrics be resent on failure?


### `timestamp_field` [plugins-outputs-graphite-timestamp_field]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"@timestamp"`

Use this field for the timestamp instead of *@timestamp* which is the default. Useful when backfilling or just getting more accurate data into graphite since you probably have a cache layer infront of Logstash.



## Common options [plugins-outputs-graphite-common-options]

These configuration options are supported by all output plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`codec`](#plugins-outputs-graphite-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-outputs-graphite-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-outputs-graphite-id) | [string](/reference/configuration-file-structure.md#string) | No |

### `codec` [plugins-outputs-graphite-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for output data. Output codecs are a convenient method for encoding your data before it leaves the output without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-outputs-graphite-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance. By default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-outputs-graphite-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type. For example, if you have 2 graphite outputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
output {
  graphite {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::




