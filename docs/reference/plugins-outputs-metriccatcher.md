---
navigation_title: "metriccatcher"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-outputs-metriccatcher.html
---

# Metriccatcher output plugin [plugins-outputs-metriccatcher]


* Plugin version: v3.0.4
* Released on: 2018-04-06
* [Changelog](https://github.com/logstash-plugins/logstash-output-metriccatcher/blob/v3.0.4/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://reference/output-metriccatcher-index.md).

## Installation [_installation_38]

For plugins not bundled by default, it is easy to install by running `bin/logstash-plugin install logstash-output-metriccatcher`. See [Working with plugins](/reference/working-with-plugins.md) for more details.


## Getting help [_getting_help_95]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-output-metriccatcher). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_95]

This output ships metrics to MetricCatcher, allowing you to utilize Coda Hale’s Metrics.

More info on MetricCatcher: [https://github.com/clearspring/MetricCatcher](https://github.com/clearspring/MetricCatcher)

At Clearspring, we use it to count the response codes from Apache logs:

```ruby
    metriccatcher {
        host => "localhost"
        port => "1420"
        type => "apache-access"
        fields => [ "response" ]
        meter => {
            "%{host}.apache.response.%{response}" => "1"
            }
    }
```


## Metriccatcher Output Configuration Options [plugins-outputs-metriccatcher-options]

This plugin supports the following configuration options plus the [Common options](#plugins-outputs-metriccatcher-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`biased`](#plugins-outputs-metriccatcher-biased) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`counter`](#plugins-outputs-metriccatcher-counter) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`gauge`](#plugins-outputs-metriccatcher-gauge) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`host`](#plugins-outputs-metriccatcher-host) | [string](/reference/configuration-file-structure.md#string) | No |
| [`meter`](#plugins-outputs-metriccatcher-meter) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`port`](#plugins-outputs-metriccatcher-port) | [number](/reference/configuration-file-structure.md#number) | No |
| [`timer`](#plugins-outputs-metriccatcher-timer) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`uniform`](#plugins-outputs-metriccatcher-uniform) | [hash](/reference/configuration-file-structure.md#hash) | No |

Also see [Common options](#plugins-outputs-metriccatcher-common-options) for a list of options supported by all output plugins.

 

### `biased` [plugins-outputs-metriccatcher-biased]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* There is no default value for this setting.

The metrics to send. This supports dynamic strings like `%{{host}}` for metric names and also for values. This is a hash field with key of the metric name, value of the metric value.

The value will be coerced to a floating point value. Values which cannot be coerced will zero (0)


### `counter` [plugins-outputs-metriccatcher-counter]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* There is no default value for this setting.

The metrics to send. This supports dynamic strings like `%{{host}}` for metric names and also for values. This is a hash field with key of the metric name, value of the metric value. Example:

```ruby
  counter => { "%{host}.apache.hits.%{response} => "1" }
```

The value will be coerced to a floating point value. Values which cannot be coerced will zero (0)


### `gauge` [plugins-outputs-metriccatcher-gauge]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* There is no default value for this setting.

The metrics to send. This supports dynamic strings like `%{{host}}` for metric names and also for values. This is a hash field with key of the metric name, value of the metric value.

The value will be coerced to a floating point value. Values which cannot be coerced will zero (0)


### `host` [plugins-outputs-metriccatcher-host]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"localhost"`

The address of the MetricCatcher


### `meter` [plugins-outputs-metriccatcher-meter]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* There is no default value for this setting.

The metrics to send. This supports dynamic strings like `%{{host}}` for metric names and also for values. This is a hash field with key of the metric name, value of the metric value.

The value will be coerced to a floating point value. Values which cannot be coerced will zero (0)


### `port` [plugins-outputs-metriccatcher-port]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `1420`

The port to connect on your MetricCatcher


### `timer` [plugins-outputs-metriccatcher-timer]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* There is no default value for this setting.

The metrics to send. This supports dynamic strings like `%{{host}}` for metric names and also for values. This is a hash field with key of the metric name, value of the metric value. Example:

```ruby
  timer => { "%{host}.apache.response_time => "%{response_time}" }
```

The value will be coerced to a floating point value. Values which cannot be coerced will zero (0)


### `uniform` [plugins-outputs-metriccatcher-uniform]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* There is no default value for this setting.

The metrics to send. This supports dynamic strings like `%{{host}}` for metric names and also for values. This is a hash field with key of the metric name, value of the metric value.

The value will be coerced to a floating point value. Values which cannot be coerced will zero (0)



## Common options [plugins-outputs-metriccatcher-common-options]

These configuration options are supported by all output plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`codec`](#plugins-outputs-metriccatcher-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-outputs-metriccatcher-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-outputs-metriccatcher-id) | [string](/reference/configuration-file-structure.md#string) | No |

### `codec` [plugins-outputs-metriccatcher-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for output data. Output codecs are a convenient method for encoding your data before it leaves the output without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-outputs-metriccatcher-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance. By default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-outputs-metriccatcher-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type. For example, if you have 2 metriccatcher outputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
output {
  metriccatcher {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::




