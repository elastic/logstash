---
navigation_title: "jmx"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-inputs-jmx.html
---

# Jmx input plugin [plugins-inputs-jmx]


* Plugin version: v3.0.7
* Released on: 2018-08-13
* [Changelog](https://github.com/logstash-plugins/logstash-input-jmx/blob/v3.0.7/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://docs/reference/input-jmx-index.md).

## Installation [_installation_5]

For plugins not bundled by default, it is easy to install by running `bin/logstash-plugin install logstash-input-jmx`. See [Working with plugins](/reference/working-with-plugins.md) for more details.


## Getting help [_getting_help_34]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-input-jmx). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_34]

This input plugin permits to retrieve metrics from remote Java applications using JMX. Every `polling_frequency`, it scans a folder containing json configuration files describing JVMs to monitor with metrics to retrieve. Then a pool of threads will retrieve metrics and create events.


## The configuration [_the_configuration]

In Logstash configuration, you must set the polling frequency, the number of thread used to poll metrics and a directory absolute path containing json files with the configuration per jvm of metrics to retrieve. Logstash input configuration example:

```ruby
    jmx {
      //Required
      path => "/apps/logstash_conf/jmxconf"
      //Optional, default 60s
      polling_frequency => 15
      type => "jmx"
      //Optional, default 4
      nb_thread => 4
    }
```

Json JMX configuration example:

```js
    {
      //Required, JMX listening host/ip
      "host" : "192.168.1.2",
      //Required, JMX listening port
      "port" : 1335,
      //Optional, the username to connect to JMX
      "username" : "user",
      //Optional, the password to connect to JMX
      "password": "pass",
      //Optional, use this alias as a prefix in the metric name. If not set use <host>_<port>
      "alias" : "test.homeserver.elasticsearch",
      //Required, list of JMX metrics to retrieve
      "queries" : [
      {
        //Required, the object name of Mbean to request
        "object_name" : "java.lang:type=Memory",
        //Optional, use this alias in the metrics value instead of the object_name
        "object_alias" : "Memory"
      }, {
        "object_name" : "java.lang:type=Runtime",
        //Optional, set of attributes to retrieve. If not set retrieve
        //all metrics available on the configured object_name.
        "attributes" : [ "Uptime", "StartTime" ],
        "object_alias" : "Runtime"
      }, {
        //object_name can be configured with * to retrieve all matching Mbeans
        "object_name" : "java.lang:type=GarbageCollector,name=*",
        "attributes" : [ "CollectionCount", "CollectionTime" ],
        //object_alias can be based on specific value from the object_name thanks to ${<varname>}.
        //In this case ${type} will be replaced by GarbageCollector...
        "object_alias" : "${type}.${name}"
      }, {
        "object_name" : "java.nio:type=BufferPool,name=*",
        "object_alias" : "${type}.${name}"
      } ]
    }
```

Here are examples of generated events. When returned metrics value type is number/boolean it is stored in `metric_value_number` event field otherwise it is stored in `metric_value_string` event field.

```ruby
    {
      "@version" => "1",
      "@timestamp" => "2014-02-18T20:57:27.688Z",
      "host" => "192.168.1.2",
      "path" => "/apps/logstash_conf/jmxconf",
      "type" => "jmx",
      "metric_path" => "test.homeserver.elasticsearch.GarbageCollector.ParNew.CollectionCount",
      "metric_value_number" => 2212
    }
```

```ruby
    {
      "@version" => "1",
      "@timestamp" => "2014-02-18T20:58:06.376Z",
      "host" => "localhost",
      "path" => "/apps/logstash_conf/jmxconf",
      "type" => "jmx",
      "metric_path" => "test.homeserver.elasticsearch.BufferPool.mapped.ObjectName",
      "metric_value_string" => "java.nio:type=BufferPool,name=mapped"
    }
```


## Jmx Input Configuration Options [plugins-inputs-jmx-options]

This plugin supports the following configuration options plus the [Common options](#plugins-inputs-jmx-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`nb_thread`](#plugins-inputs-jmx-nb_thread) | [number](/reference/configuration-file-structure.md#number) | No |
| [`path`](#plugins-inputs-jmx-path) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`polling_frequency`](#plugins-inputs-jmx-polling_frequency) | [number](/reference/configuration-file-structure.md#number) | No |

Also see [Common options](#plugins-inputs-jmx-common-options) for a list of options supported by all input plugins.

 

### `nb_thread` [plugins-inputs-jmx-nb_thread]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `4`

Indicate number of thread launched to retrieve metrics


### `path` [plugins-inputs-jmx-path]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Path where json conf files are stored


### `polling_frequency` [plugins-inputs-jmx-polling_frequency]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `60`

Indicate interval between two jmx metrics retrieval (in s)



## Common options [plugins-inputs-jmx-common-options]

These configuration options are supported by all input plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`add_field`](#plugins-inputs-jmx-add_field) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`codec`](#plugins-inputs-jmx-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-inputs-jmx-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-inputs-jmx-id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`tags`](#plugins-inputs-jmx-tags) | [array](/reference/configuration-file-structure.md#array) | No |
| [`type`](#plugins-inputs-jmx-type) | [string](/reference/configuration-file-structure.md#string) | No |

### `add_field` [plugins-inputs-jmx-add_field]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

Add a field to an event


### `codec` [plugins-inputs-jmx-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for input data. Input codecs are a convenient method for decoding your data before it enters the input, without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-inputs-jmx-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance by default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-inputs-jmx-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type, for example, if you have 2 jmx inputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
input {
  jmx {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::



### `tags` [plugins-inputs-jmx-tags]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

Add any number of arbitrary tags to your event.

This can help with processing later.


### `type` [plugins-inputs-jmx-type]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a `type` field to all events handled by this input.

Types are used mainly for filter activation.

The type is stored as part of the event itself, so you can also use the type to search for it in Kibana.

If you try to set a type on an event that already has one (for example when you send an event from a shipper to an indexer) then a new input will not override the existing type. A type set at the shipper stays with that event for its life even when sent to another Logstash server.



