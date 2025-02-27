---
navigation_title: "java_generator"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-inputs-java_generator.html
---

# Java_generator input plugin [plugins-inputs-java_generator]


**{{ls}} Core Plugin.** The java_generator input plugin cannot be installed or uninstalled independently of {{ls}}.

## Getting help [_getting_help_30]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash).


## Description [_description_30]

Generate synthetic log events.

This plugin generates a stream of synthetic events that can be used to test the correctness or performance of a Logstash pipeline.


## Java_generator Input Configuration Options [plugins-inputs-java_generator-options]

This plugin supports the following configuration options plus the [Common options](#plugins-inputs-java_generator-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`count`](#plugins-inputs-java_generator-count) | [number](/reference/configuration-file-structure.md#number) | No |
| [`eps`](#plugins-inputs-java_generator-eps) | [number](/reference/configuration-file-structure.md#number) | No |
| [`lines`](#plugins-inputs-java_generator-lines) | [array](/reference/configuration-file-structure.md#array) | No |
| [`message`](#plugins-inputs-java_generator-message) | [string](/reference/configuration-file-structure.md#string) | No |
| [`threads`](#plugins-inputs-java_generator-threads) | [number](/reference/configuration-file-structure.md#number) | No |

Also see [Common options](#plugins-inputs-java_generator-common-options) for a list of options supported by all input plugins.

 

### `count` [plugins-inputs-java_generator-count]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `0`

Sets the number of events that should be generated.

The default, `0`, means generate an unlimited number of events.


### `eps` [plugins-inputs-java_generator-eps]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `0`

Sets the rate at which events should be generated. Fractional values may be specified. For example, a rate of `0.25` means that one event will be generated every four seconds.

The default, `0`, means generate events as fast as possible.


### `lines` [plugins-inputs-java_generator-lines]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

The lines to emit, in order. This option overrides the *message* setting if it has also been specified.

Example:

```ruby
    input {
      java_generator {
        lines => [
          "line 1",
          "line 2",
          "line 3"
        ]
        # Emit all lines 2 times.
        count => 2
      }
    }
```

The above will emit a series of three events `line 1` then `line 2` then `line 3` two times for a total of 6 events.


### `message` [plugins-inputs-java_generator-message]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"Hello world!"`

The message string to use in the event.


### `threads` [plugins-inputs-java_generator-threads]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `1`

Increasing the number of generator threads up to about the number of CPU cores generally increases overall event throughput. The `count`, `eps`, and `lines` settings all apply on a per-thread basis. In other words, each thread will emit the number of events specified in the `count` setting for a total of `threads * count` events. Each thread will emit events at the `eps` rate for a total rate of `threads * eps`, and each thread will emit each line specified in the `lines` option.



## Common options [plugins-inputs-java_generator-common-options]

These configuration options are supported by all input plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`add_field`](#plugins-inputs-java_generator-add_field) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`codec`](#plugins-inputs-java_generator-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-inputs-java_generator-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-inputs-java_generator-id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`tags`](#plugins-inputs-java_generator-tags) | [array](/reference/configuration-file-structure.md#array) | No |
| [`type`](#plugins-inputs-java_generator-type) | [string](/reference/configuration-file-structure.md#string) | No |

### `add_field` [plugins-inputs-java_generator-add_field]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

Add a field to an event


### `codec` [plugins-inputs-java_generator-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for input data. Input codecs are a convenient method for decoding your data before it enters the input, without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-inputs-java_generator-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance by default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-inputs-java_generator-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type, for example, if you have 2 java_generator inputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
input {
  java_generator {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::



### `tags` [plugins-inputs-java_generator-tags]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

Add any number of arbitrary tags to your event.

This can help with processing later.


### `type` [plugins-inputs-java_generator-type]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a `type` field to all events handled by this input.

Types are used mainly for filter activation.

The type is stored as part of the event itself, so you can also use the type to search for it in Kibana.

If you try to set a type on an event that already has one (for example when you send an event from a shipper to an indexer) then a new input will not override the existing type. A type set at the shipper stays with that event for its life even when sent to another Logstash server.



