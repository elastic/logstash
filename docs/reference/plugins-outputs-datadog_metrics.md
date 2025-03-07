---
navigation_title: "datadog_metrics"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-outputs-datadog_metrics.html
---

# Datadog_metrics output plugin [plugins-outputs-datadog_metrics]


* Plugin version: v3.0.7
* Released on: 2024-10-25
* [Changelog](https://github.com/logstash-plugins/logstash-output-datadog_metrics/blob/v3.0.7/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://reference/output-datadog_metrics-index.md).

## Installation [_installation_24]

For plugins not bundled by default, it is easy to install by running `bin/logstash-plugin install logstash-output-datadog_metrics`. See [Working with plugins](/reference/working-with-plugins.md) for more details.


## Getting help [_getting_help_70]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-output-datadog_metrics). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_70]

This output lets you send metrics to DataDogHQ based on Logstash events. Default `queue_size` and `timeframe` are low in order to provide near realtime alerting. If you do not use Datadog for alerting, consider raising these thresholds.


## Datadog_metrics Output Configuration Options [plugins-outputs-datadog_metrics-options]

This plugin supports the following configuration options plus the [Common options](#plugins-outputs-datadog_metrics-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`api_key`](#plugins-outputs-datadog_metrics-api_key) | [password](/reference/configuration-file-structure.md#password) | Yes |
| [`api_url`](#plugins-outputs-datadog_metrics-api_url) | [string](/reference/configuration-file-structure.md#string) | No |
| [`dd_tags`](#plugins-outputs-datadog_metrics-dd_tags) | [array](/reference/configuration-file-structure.md#array) | No |
| [`device`](#plugins-outputs-datadog_metrics-device) | [string](/reference/configuration-file-structure.md#string) | No |
| [`host`](#plugins-outputs-datadog_metrics-host) | [string](/reference/configuration-file-structure.md#string) | No |
| [`metric_name`](#plugins-outputs-datadog_metrics-metric_name) | [string](/reference/configuration-file-structure.md#string) | No |
| [`metric_type`](#plugins-outputs-datadog_metrics-metric_type) | [string](/reference/configuration-file-structure.md#string), one of `["gauge", "counter", "%{{metric_type}}"]` | No |
| [`metric_value`](#plugins-outputs-datadog_metrics-metric_value) | <<,>> | No |
| [`queue_size`](#plugins-outputs-datadog_metrics-queue_size) | [number](/reference/configuration-file-structure.md#number) | No |
| [`timeframe`](#plugins-outputs-datadog_metrics-timeframe) | [number](/reference/configuration-file-structure.md#number) | No |

Also see [Common options](#plugins-outputs-datadog_metrics-common-options) for a list of options supported by all output plugins.

 

### `api_key` [plugins-outputs-datadog_metrics-api_key]

* This is a required setting.
* Value type is [password](/reference/configuration-file-structure.md#password)
* There is no default value for this setting.

Your DatadogHQ API key. [https://app.datadoghq.com/account/settings#api](https://app.datadoghq.com/account/settings#api)


### `api_url` [plugins-outputs-datadog_metrics-api_url]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"https://api.datadoghq.com/api/v1/series"`

Set the api endpoint for Datadog EU Site users


### `dd_tags` [plugins-outputs-datadog_metrics-dd_tags]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

Set any custom tags for this event, default are the Logstash tags if any.


### `device` [plugins-outputs-datadog_metrics-device]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"%{{metric_device}}"`

The name of the device that produced the metric.


### `host` [plugins-outputs-datadog_metrics-host]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `%{{host}}`

The name of the host that produced the metric.


### `metric_name` [plugins-outputs-datadog_metrics-metric_name]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"%{{metric_name}}"`

The name of the time series.


### `metric_type` [plugins-outputs-datadog_metrics-metric_type]

* Value can be any of: `gauge`, `counter`, `%{{metric_type}}`
* Default value is `"%{{metric_type}}"`

The type of the metric.


### `metric_value` [plugins-outputs-datadog_metrics-metric_value]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"%{{metric_value}}"`

The value.


### `queue_size` [plugins-outputs-datadog_metrics-queue_size]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `10`

How many events to queue before flushing to Datadog prior to schedule set in `@timeframe`


### `timeframe` [plugins-outputs-datadog_metrics-timeframe]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `10`

How often (in seconds) to flush queued events to Datadog



## Common options [plugins-outputs-datadog_metrics-common-options]

These configuration options are supported by all output plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`codec`](#plugins-outputs-datadog_metrics-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-outputs-datadog_metrics-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-outputs-datadog_metrics-id) | [string](/reference/configuration-file-structure.md#string) | No |

### `codec` [plugins-outputs-datadog_metrics-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for output data. Output codecs are a convenient method for encoding your data before it leaves the output without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-outputs-datadog_metrics-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance. By default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-outputs-datadog_metrics-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type. For example, if you have 2 datadog_metrics outputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
output {
  datadog_metrics {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::




