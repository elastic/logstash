---
navigation_title: "java_stdout"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-outputs-java_stdout.html
---

# Java_stdout output plugin [plugins-outputs-java_stdout]


**{{ls}} Core Plugin.** The java_stdout output plugin cannot be installed or uninstalled independently of {{ls}}.

## Getting help [_getting_help_88]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash).


## Description [_description_88]

Prints events to the STDOUT of the shell running Logstash. This output is convenient for debugging plugin configurations by providing instant access to event data after it has passed through the inputs and filters.

For example, the following output configuration in conjunction with the Logstash `-e` command-line flag, will allow you to see the results of your event pipeline for quick iteration.

```ruby
    output {
      java_stdout {}
    }
```

Useful codecs include:

`java_line`: outputs event data in JSON format followed by an end-of-line character. This is the default codec for java_stdout.

```ruby
    output {
      stdout { }
    }
```


## Java_stdout Output Configuration Options [plugins-outputs-java_stdout-options]

There are no special configuration options for this plugin, but it does support the [Common options](#plugins-outputs-java_stdout-common-options).


## Common options [plugins-outputs-java_stdout-common-options]

These configuration options are supported by all output plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`codec`](#plugins-outputs-java_stdout-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-outputs-java_stdout-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-outputs-java_stdout-id) | [string](/reference/configuration-file-structure.md#string) | No |

### `codec` [plugins-outputs-java_stdout-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"java_line"`

The codec used for output data. Output codecs are a convenient method for encoding your data before it leaves the output without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-outputs-java_stdout-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance. By default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-outputs-java_stdout-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type. For example, if you have 2 java_stdout outputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
output {
  java_stdout {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::




