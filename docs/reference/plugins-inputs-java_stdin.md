---
navigation_title: "java_stdin"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-inputs-java_stdin.html
---

# Java_stdin input plugin [plugins-inputs-java_stdin]


**{{ls}} Core Plugin.** The java_stdin input plugin cannot be installed or uninstalled independently of {{ls}}.

## Getting help [_getting_help_31]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash).


## Description [_description_31]

Read events from standard input.

By default, each event is assumed to be terminated by end-of-line. If you want events delimited in a different method, you’ll need to use a codec with support for that encoding.


## Java_stdin Input Configuration Options [plugins-inputs-java_stdin-options]

There are no special configuration options for this plugin, but it does support the [Common options](#plugins-inputs-java_stdin-common-options).


## Common options [plugins-inputs-java_stdin-common-options]

These configuration options are supported by all input plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`add_field`](#plugins-inputs-java_stdin-add_field) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`codec`](#plugins-inputs-java_stdin-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-inputs-java_stdin-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-inputs-java_stdin-id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`tags`](#plugins-inputs-java_stdin-tags) | [array](/reference/configuration-file-structure.md#array) | No |
| [`type`](#plugins-inputs-java_stdin-type) | [string](/reference/configuration-file-structure.md#string) | No |

### `add_field` [plugins-inputs-java_stdin-add_field]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

Add a field to an event


### `codec` [plugins-inputs-java_stdin-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"java_line"`

The codec used for input data. Input codecs are a convenient method for decoding your data before it enters the input, without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-inputs-java_stdin-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance by default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-inputs-java_stdin-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type, for example, if you have 2 java_stdin inputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
input {
  java_stdin {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::



### `tags` [plugins-inputs-java_stdin-tags]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

Add any number of arbitrary tags to your event.

This can help with processing later.


### `type` [plugins-inputs-java_stdin-type]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a `type` field to all events handled by this input.

Types are used mainly for filter activation.

The type is stored as part of the event itself, so you can also use the type to search for it in Kibana.

If you try to set a type on an event that already has one (for example when you send an event from a shipper to an indexer) then a new input will not override the existing type. A type set at the shipper stays with that event for its life even when sent to another Logstash server.



