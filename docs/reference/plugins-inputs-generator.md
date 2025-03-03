---
navigation_title: "generator"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-inputs-generator.html
---

# Generator input plugin [plugins-inputs-generator]


* Plugin version: v3.1.0
* Released on: 2021-11-04
* [Changelog](https://github.com/logstash-plugins/logstash-input-generator/blob/v3.1.0/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://reference/input-generator-index.md).

## Getting help [_getting_help_20]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-input-generator). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_21]

Generate random log events.

The general intention of this is to test performance of plugins.

An event is generated first


## Compatibility with the Elastic Common Schema (ECS) [plugins-inputs-generator-ecs]

This plugin uses different field names depending on whether [ECS-compatibility](ecs://reference/index.md) in enabled (see also [`ecs_compatibility`](#plugins-inputs-generator-ecs_compatibility)).

| ECS Disabled | ECS v1, v8 | Description |
| --- | --- | --- |
| `host` | `[host][name]` | The name of the {{ls}} host that processed the event |
| `sequence` | `[event][sequence]` | The sequence number for the generated event |


## Generator Input Configuration Options [plugins-inputs-generator-options]

This plugin supports the following configuration options plus the [Common options](#plugins-inputs-generator-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`count`](#plugins-inputs-generator-count) | [number](/reference/configuration-file-structure.md#number) | No |
| [`ecs_compatibility`](#plugins-inputs-generator-ecs_compatibility) | [string](/reference/configuration-file-structure.md#string) | No |
| [`lines`](#plugins-inputs-generator-lines) | [array](/reference/configuration-file-structure.md#array) | No |
| [`message`](#plugins-inputs-generator-message) | [string](/reference/configuration-file-structure.md#string) | No |
| [`threads`](#plugins-inputs-generator-threads) | [number](/reference/configuration-file-structure.md#number) | No |

Also see [Common options](#plugins-inputs-generator-common-options) for a list of options supported by all input plugins.

 

### `count` [plugins-inputs-generator-count]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `0`

Set how many messages should be generated.

The default, `0`, means generate an unlimited number of events.


### `ecs_compatibility` [plugins-inputs-generator-ecs_compatibility]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Supported values are:

    * `disabled`: uses backwards compatible field names, such as `[host]`
    * `v1`, `v8`: uses fields that are compatible with ECS, such as `[host][name]`


Controls this plugin’s compatibility with the [Elastic Common Schema (ECS)][Elastic Common Schema (ECS)](ecs://reference/index.md)). See [Compatibility with the Elastic Common Schema (ECS)](#plugins-inputs-generator-ecs) for detailed information.

**Sample output: ECS enabled**

```ruby
{
    "message" => "Hello world!",
    "event" => {
        "sequence" => 0
    },
    "host" => {
        "name" => "the-machine"
    }
}
```

**Sample output: ECS disabled**

```ruby
{
    "message" => "Hello world!",
    "sequence" => 0,
    "host" => "the-machine"
}
```


### `lines` [plugins-inputs-generator-lines]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

The lines to emit, in order. This option cannot be used with the *message* setting.

Example:

```ruby
    input {
      generator {
        lines => [
          "line 1",
          "line 2",
          "line 3"
        ]
        # Emit all lines 3 times.
        count => 3
      }
    }
```

The above will emit `line 1` then `line 2` then `line 3`, then `line 1`, etc…​


### `message` [plugins-inputs-generator-message]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"Hello world!"`

The message string to use in the event.

If you set this to `stdin` then this plugin will read a single line from stdin and use that as the message string for every event.

Otherwise, this value will be used verbatim as the event message.


### `threads` [plugins-inputs-generator-threads]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `1`



## Common options [plugins-inputs-generator-common-options]

These configuration options are supported by all input plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`add_field`](#plugins-inputs-generator-add_field) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`codec`](#plugins-inputs-generator-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-inputs-generator-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-inputs-generator-id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`tags`](#plugins-inputs-generator-tags) | [array](/reference/configuration-file-structure.md#array) | No |
| [`type`](#plugins-inputs-generator-type) | [string](/reference/configuration-file-structure.md#string) | No |

### `add_field` [plugins-inputs-generator-add_field]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

Add a field to an event


### `codec` [plugins-inputs-generator-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for input data. Input codecs are a convenient method for decoding your data before it enters the input, without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-inputs-generator-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance by default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-inputs-generator-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type, for example, if you have 2 generator inputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
input {
  generator {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::



### `tags` [plugins-inputs-generator-tags]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

Add any number of arbitrary tags to your event.

This can help with processing later.


### `type` [plugins-inputs-generator-type]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a `type` field to all events handled by this input.

Types are used mainly for filter activation.

The type is stored as part of the event itself, so you can also use the type to search for it in Kibana.

If you try to set a type on an event that already has one (for example when you send an event from a shipper to an indexer) then a new input will not override the existing type. A type set at the shipper stays with that event for its life even when sent to another Logstash server.
