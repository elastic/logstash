---
navigation_title: "sink"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-outputs-sink.html
---

# Sink output plugin [plugins-outputs-sink]


**{{ls}} Core Plugin.** The sink output plugin cannot be installed or uninstalled independently of {{ls}}.

## Getting help [_getting_help_108]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash).


## Description [_description_108]

An event sink that discards any events received. Generally useful for testing the performance of inputs and filters.


## Sink Output Configuration Options [plugins-outputs-sink-options]

There are no special configuration options for this plugin, but it does support the [Common options](#plugins-outputs-sink-common-options).


## Common options [plugins-outputs-sink-common-options]

These configuration options are supported by all output plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`codec`](#plugins-outputs-sink-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-outputs-sink-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-outputs-sink-id) | [string](/reference/configuration-file-structure.md#string) | No |

### `codec` [plugins-outputs-sink-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for output data. Output codecs are a convenient method for encoding your data before it leaves the output without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-outputs-sink-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance. By default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-outputs-sink-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type. For example, if you have 2 sink outputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
output {
  sink {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::




