---
navigation_title: "stdout"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-outputs-stdout.html
---

# Stdout output plugin [plugins-outputs-stdout]


* Plugin version: v3.1.4
* Released on: 2018-04-06
* [Changelog](https://github.com/logstash-plugins/logstash-output-stdout/blob/v3.1.4/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://docs/reference/output-stdout-index.md).

## Getting help [_getting_help_113]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-output-stdout). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_113]

A simple output which prints to the STDOUT of the shell running Logstash. This output can be quite convenient when debugging plugin configurations, by allowing instant access to the event data after it has passed through the inputs and filters.

For example, the following output configuration, in conjunction with the Logstash `-e` command-line flag, will allow you to see the results of your event pipeline for quick iteration.

```ruby
    output {
      stdout {}
    }
```

Useful codecs include:

`rubydebug`: outputs event data using the ruby "awesome_print" [library](http://rubygems.org/gems/awesome_print) This is the default codec for stdout.

```ruby
    output {
      stdout { }
    }
```

`json`: outputs event data in structured JSON format

```ruby
    output {
      stdout { codec => json }
    }
```


## Stdout Output Configuration Options [plugins-outputs-stdout-options]

There are no special configuration options for this plugin, but it does support the [Common options](#plugins-outputs-stdout-common-options).


## Common options [plugins-outputs-stdout-common-options]

These configuration options are supported by all output plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`codec`](#plugins-outputs-stdout-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-outputs-stdout-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-outputs-stdout-id) | [string](/reference/configuration-file-structure.md#string) | No |

### `codec` [plugins-outputs-stdout-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"rubydebug"`

The codec used for output data. Output codecs are a convenient method for encoding your data before it leaves the output without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-outputs-stdout-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance. By default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-outputs-stdout-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type. For example, if you have 2 stdout outputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
output {
  stdout {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::




