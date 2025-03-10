---
navigation_title: "graphite"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-codecs-graphite.html
---

# Graphite codec plugin [plugins-codecs-graphite]


* Plugin version: v3.0.6
* Released on: 2021-08-12
* [Changelog](https://github.com/logstash-plugins/logstash-codec-graphite/blob/v3.0.6/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://reference/codec-graphite-index.md).

## Getting help [_getting_help_183]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-codec-graphite). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_182]

This codec will encode and decode Graphite formated lines.


## Graphite Codec Configuration Options [plugins-codecs-graphite-options]

| Setting | Input type | Required |
| --- | --- | --- |
| [`exclude_metrics`](#plugins-codecs-graphite-exclude_metrics) | [array](/reference/configuration-file-structure.md#array) | No |
| [`fields_are_metrics`](#plugins-codecs-graphite-fields_are_metrics) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`include_metrics`](#plugins-codecs-graphite-include_metrics) | [array](/reference/configuration-file-structure.md#array) | No |
| [`metrics`](#plugins-codecs-graphite-metrics) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`metrics_format`](#plugins-codecs-graphite-metrics_format) | [string](/reference/configuration-file-structure.md#string) | No |

 

### `exclude_metrics` [plugins-codecs-graphite-exclude_metrics]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `["%{[^}]+}"]`

Exclude regex matched metric names, by default exclude unresolved `%{{field}}` strings


### `fields_are_metrics` [plugins-codecs-graphite-fields_are_metrics]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Indicate that the event @fields should be treated as metrics and will be sent as is to graphite


### `include_metrics` [plugins-codecs-graphite-include_metrics]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[".*"]`

Include only regex matched metric names


### `metrics` [plugins-codecs-graphite-metrics]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

The metric(s) to use. This supports dynamic strings like `%{{host}}` for metric names and also for values. This is a hash field with key of the metric name, value of the metric value. Example:

```ruby
    [ "%{host}/uptime", "%{uptime_1m}" ]
```

The value will be coerced to a floating point value. Values which cannot be coerced will zero (0)


### `metrics_format` [plugins-codecs-graphite-metrics_format]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"*"`

Defines format of the metric string. The placeholder `*` will be replaced with the name of the actual metric. This supports dynamic strings like `%{{host}}`.

```ruby
    metrics_format => "%{host}.foo.bar.*.sum"
```

::::{note}
If no metrics_format is defined the name of the metric will be used as fallback.
::::




