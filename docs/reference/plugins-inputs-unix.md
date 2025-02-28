---
navigation_title: "unix"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-inputs-unix.html
---

# Unix input plugin [plugins-inputs-unix]


* Plugin version: v3.1.2
* Released on: 2022-10-03
* [Changelog](https://github.com/logstash-plugins/logstash-input-unix/blob/v3.1.2/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://reference/input-unix-index.md).

## Getting help [_getting_help_60]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-input-unix). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_60]

Read events over a UNIX socket.

Like `stdin` and `file` inputs, each event is assumed to be one line of text.

Can either accept connections from clients or connect to a server, depending on `mode`.


## Compatibility with the Elastic Common Schema (ECS) [plugins-inputs-unix-ecs]

This plugin adds extra fields about the event’s source. Configure the [`ecs_compatibility`](#plugins-inputs-unix-ecs_compatibility) option if you want to ensure that these fields are compatible with [ECS](ecs://reference/index.md).

These fields are added after the event has been decoded by the appropriate codec, and will not overwrite existing values.

| ECS Disabled | ECS v1 , v8 | Description |
| --- | --- | --- |
| `host` | `[host][name]` | The name of the {{ls}} host that processed the event |
| `path` | `[file][path]` | The socket path configured in the plugin |


## Unix Input Configuration Options [plugins-inputs-unix-options]

This plugin supports the following configuration options plus the [Common options](#plugins-inputs-unix-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`data_timeout`](#plugins-inputs-unix-data_timeout) | [number](/reference/configuration-file-structure.md#number) | No |
| [`ecs_compatibility`](#plugins-inputs-unix-ecs_compatibility) | [string](/reference/configuration-file-structure.md#string) | No |
| [`force_unlink`](#plugins-inputs-unix-force_unlink) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`mode`](#plugins-inputs-unix-mode) | [string](/reference/configuration-file-structure.md#string), one of `["server", "client"]` | No |
| [`path`](#plugins-inputs-unix-path) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`socket_not_present_retry_interval_seconds`](#plugins-inputs-unix-socket_not_present_retry_interval_seconds) | [number](/reference/configuration-file-structure.md#number) | Yes |

Also see [Common options](#plugins-inputs-unix-common-options) for a list of options supported by all input plugins.

 

### `data_timeout` [plugins-inputs-unix-data_timeout]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `-1`

The *read* timeout in seconds. If a particular connection is idle for more than this timeout period, we will assume it is dead and close it.

If you never want to timeout, use -1.


### `ecs_compatibility` [plugins-inputs-unix-ecs_compatibility]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Supported values are:

    * `disabled`: uses backwards compatible field names, such as `[host]`
    * `v1`, `v8`: uses fields that are compatible with ECS, such as `[host][name]`


Controls this plugin’s compatibility with the [Elastic Common Schema (ECS)][Elastic Common Schema (ECS)](ecs://reference/index.md)). See [Compatibility with the Elastic Common Schema (ECS)](#plugins-inputs-unix-ecs) for detailed information.

**Sample output: ECS enabled**

```ruby
{
    "@timestamp" => 2021-11-16T13:20:06.308Z,
    "file" => {
      "path" => "/tmp/sock41299"
    },
    "host" => {
      "name" => "deus-ex-machina"
    },
    "message" => "foo"
}
```

**Sample output: ECS disabled**

```ruby
{
    "@timestamp" => 2021-11-16T13:20:06.308Z,
    "path" => "/tmp/sock41299",
    "host" => "deus-ex-machina",
    "message" => "foo"
}
```


### `force_unlink` [plugins-inputs-unix-force_unlink]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Remove socket file in case of EADDRINUSE failure


### `mode` [plugins-inputs-unix-mode]

* Value can be any of: `server`, `client`
* Default value is `"server"`

Mode to operate in. `server` listens for client connections, `client` connects to a server.


### `path` [plugins-inputs-unix-path]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

When mode is `server`, the path to listen on. When mode is `client`, the path to connect to.


### `socket_not_present_retry_interval_seconds` [plugins-inputs-unix-socket_not_present_retry_interval_seconds]

* This is a required setting.
* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `5`

Amount of time in seconds to wait if the socket file is not present, before retrying. Only positive values are allowed.

This setting is only used if `mode` is `client`.



## Common options [plugins-inputs-unix-common-options]

These configuration options are supported by all input plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`add_field`](#plugins-inputs-unix-add_field) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`codec`](#plugins-inputs-unix-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-inputs-unix-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-inputs-unix-id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`tags`](#plugins-inputs-unix-tags) | [array](/reference/configuration-file-structure.md#array) | No |
| [`type`](#plugins-inputs-unix-type) | [string](/reference/configuration-file-structure.md#string) | No |

### `add_field` [plugins-inputs-unix-add_field]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

Add a field to an event


### `codec` [plugins-inputs-unix-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"line"`

The codec used for input data. Input codecs are a convenient method for decoding your data before it enters the input, without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-inputs-unix-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance by default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-inputs-unix-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type, for example, if you have 2 unix inputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
input {
  unix {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::



### `tags` [plugins-inputs-unix-tags]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

Add any number of arbitrary tags to your event.

This can help with processing later.


### `type` [plugins-inputs-unix-type]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a `type` field to all events handled by this input.

Types are used mainly for filter activation.

The type is stored as part of the event itself, so you can also use the type to search for it in Kibana.

If you try to set a type on an event that already has one (for example when you send an event from a shipper to an indexer) then a new input will not override the existing type. A type set at the shipper stays with that event for its life even when sent to another Logstash server.
