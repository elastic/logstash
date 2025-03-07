---
navigation_title: "stdin"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-inputs-stdin.html
---

# Stdin input plugin [plugins-inputs-stdin]


* Plugin version: v3.4.0
* Released on: 2021-08-04
* [Changelog](https://github.com/logstash-plugins/logstash-input-stdin/blob/v3.4.0/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://reference/input-stdin-index.md).

## Getting help [_getting_help_54]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-input-stdin). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_54]

Read events from standard input.

By default, each event is assumed to be one line. If you want to join lines, you’ll want to use the multiline codec.


## Stdin Input Configuration Options [plugins-inputs-stdin-options]

This plugin supports the following configuration options.

| Setting | Input type | Required |
| --- | --- | --- |
| [`ecs_compatibility`](#plugins-inputs-stdin-ecs_compatibility) | [string](/reference/configuration-file-structure.md#string) | No |

Also see [Common options](#plugins-inputs-stdin-common-options) for a list of options supported by all input plugins.

 

### `ecs_compatibility` [plugins-inputs-stdin-ecs_compatibility]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Supported values are:

    * `disabled`: does not use ECS-compatible field names (using `host` field to store host name)
    * `v1`,`v8`: uses fields that are compatible with Elastic Common Schema (using `[host][hostname]`)

* Default value depends on which version of Logstash is running:

    * When Logstash provides a `pipeline.ecs_compatibility` setting, its value is used as the default
    * Otherwise, the default value is `disabled`.


Controls this plugin’s compatibility with the [Elastic Common Schema (ECS)][Elastic Common Schema (ECS)](ecs://reference/index.md)).



## Common options [plugins-inputs-stdin-common-options]

These configuration options are supported by all input plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`add_field`](#plugins-inputs-stdin-add_field) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`codec`](#plugins-inputs-stdin-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-inputs-stdin-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-inputs-stdin-id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`tags`](#plugins-inputs-stdin-tags) | [array](/reference/configuration-file-structure.md#array) | No |
| [`type`](#plugins-inputs-stdin-type) | [string](/reference/configuration-file-structure.md#string) | No |

### `add_field` [plugins-inputs-stdin-add_field]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

Add a field to an event


### `codec` [plugins-inputs-stdin-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"line"`

The codec used for input data. Input codecs are a convenient method for decoding your data before it enters the input, without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-inputs-stdin-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance by default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-inputs-stdin-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type, for example, if you have 2 stdin inputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
input {
  stdin {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::



### `tags` [plugins-inputs-stdin-tags]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

Add any number of arbitrary tags to your event.

This can help with processing later.


### `type` [plugins-inputs-stdin-type]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a `type` field to all events handled by this input.

Types are used mainly for filter activation.

The type is stored as part of the event itself, so you can also use the type to search for it in Kibana.

If you try to set a type on an event that already has one (for example when you send an event from a shipper to an indexer) then a new input will not override the existing type. A type set at the shipper stays with that event for its life even when sent to another Logstash server.



