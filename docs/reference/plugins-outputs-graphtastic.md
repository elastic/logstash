---
navigation_title: "graphtastic"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-outputs-graphtastic.html
---

# Graphtastic output plugin [plugins-outputs-graphtastic]


* Plugin version: v3.0.4
* Released on: 2018-04-06
* [Changelog](https://github.com/logstash-plugins/logstash-output-graphtastic/blob/v3.0.4/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://docs/reference/output-graphtastic-index.md).

## Installation [_installation_32]

For plugins not bundled by default, it is easy to install by running `bin/logstash-plugin install logstash-output-graphtastic`. See [Working with plugins](/reference/working-with-plugins.md) for more details.


## Getting help [_getting_help_84]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-output-graphtastic). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_84]

A plugin for a newly developed Java/Spring Metrics application I didn’t really want to code this project but I couldn’t find a respectable alternative that would also run on any Windows machine - which is the problem and why I am not going with Graphite and statsd.  This application provides multiple integration options so as to make its use under your network requirements possible. This includes a REST option that is always enabled for your use in case you want to write a small script to send the occasional metric data.

Find GraphTastic here : [https://github.com/NickPadilla/GraphTastic](https://github.com/NickPadilla/GraphTastic)


## Graphtastic Output Configuration Options [plugins-outputs-graphtastic-options]

This plugin supports the following configuration options plus the [Common options](#plugins-outputs-graphtastic-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`batch_number`](#plugins-outputs-graphtastic-batch_number) | [number](/reference/configuration-file-structure.md#number) | No |
| [`context`](#plugins-outputs-graphtastic-context) | [string](/reference/configuration-file-structure.md#string) | No |
| [`error_file`](#plugins-outputs-graphtastic-error_file) | [string](/reference/configuration-file-structure.md#string) | No |
| [`host`](#plugins-outputs-graphtastic-host) | [string](/reference/configuration-file-structure.md#string) | No |
| [`integration`](#plugins-outputs-graphtastic-integration) | [string](/reference/configuration-file-structure.md#string), one of `["udp", "tcp", "rmi", "rest"]` | No |
| [`metrics`](#plugins-outputs-graphtastic-metrics) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`port`](#plugins-outputs-graphtastic-port) | [number](/reference/configuration-file-structure.md#number) | No |
| [`retries`](#plugins-outputs-graphtastic-retries) | [number](/reference/configuration-file-structure.md#number) | No |

Also see [Common options](#plugins-outputs-graphtastic-common-options) for a list of options supported by all output plugins.

 

### `batch_number` [plugins-outputs-graphtastic-batch_number]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `60`

the number of metrics to send to GraphTastic at one time. 60 seems to be the perfect amount for UDP, with default packet size.


### `context` [plugins-outputs-graphtastic-context]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"graphtastic"`

if using rest as your end point you need to also provide the application url it defaults to localhost/graphtastic.  You can customize the application url by changing the name of the .war file.  There are other ways to change the application context, but they vary depending on the Application Server in use. Please consult your application server documentation for more on application contexts.


### `error_file` [plugins-outputs-graphtastic-error_file]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `""`

setting allows you to specify where we save errored transactions this makes the most sense at this point - will need to decide on how we reintegrate these error metrics NOT IMPLEMENTED!


### `host` [plugins-outputs-graphtastic-host]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"127.0.0.1"`

host for the graphtastic server - defaults to 127.0.0.1


### `integration` [plugins-outputs-graphtastic-integration]

* Value can be any of: `udp`, `tcp`, `rmi`, `rest`
* Default value is `"udp"`

options are udp(fastest - default) - rmi(faster) - rest(fast) - tcp(don’t use TCP yet - some problems - errors out on linux)


### `metrics` [plugins-outputs-graphtastic-metrics]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

metrics hash - you will provide a name for your metric and the metric data as key value pairs.  so for example:

```ruby
metrics => { "Response" => "%{response}" }
```

example for the logstash config

```ruby
metrics => [ "Response", "%{response}" ]
```

::::{note}
you can also use the dynamic fields for the key value as well as the actual value
::::



### `port` [plugins-outputs-graphtastic-port]

* Value type is [number](/reference/configuration-file-structure.md#number)
* There is no default value for this setting.

port for the graphtastic instance - defaults to 1199 for RMI, 1299 for TCP, 1399 for UDP, and 8080 for REST


### `retries` [plugins-outputs-graphtastic-retries]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `1`

number of attempted retry after send error - currently only way to integrate errored transactions - should try and save to a file or later consumption either by graphtastic utility or by this program after connectivity is ensured to be established.



## Common options [plugins-outputs-graphtastic-common-options]

These configuration options are supported by all output plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`codec`](#plugins-outputs-graphtastic-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-outputs-graphtastic-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-outputs-graphtastic-id) | [string](/reference/configuration-file-structure.md#string) | No |

### `codec` [plugins-outputs-graphtastic-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for output data. Output codecs are a convenient method for encoding your data before it leaves the output without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-outputs-graphtastic-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance. By default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-outputs-graphtastic-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type. For example, if you have 2 graphtastic outputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
output {
  graphtastic {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::




