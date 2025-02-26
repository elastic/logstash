---
navigation_title: "redis"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-inputs-redis.html
---

# Redis input plugin [plugins-inputs-redis]


* Plugin version: v3.7.1
* Released on: 2024-08-01
* [Changelog](https://github.com/logstash-plugins/logstash-input-redis/blob/v3.7.1/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://docs/reference/input-redis-index.md).

## Getting help [_getting_help_44]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-input-redis). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_44]

This input will read events from a Redis instance; it supports both Redis channels and lists. The list command (BLPOP) used by Logstash is supported in Redis v1.3.1+, and the channel commands used by Logstash are found in Redis v1.3.8+. While you may be able to make these Redis versions work, the best performance and stability will be found in more recent stable versions.  Versions 2.6.0+ are recommended.

For more information about Redis, see [http://redis.io/](http://redis.io/)

`batch_count` note: If you use the `batch_count` setting, you **must** use a Redis version 2.6.0 or newer. Anything older does not support the operations used by batching.


## Redis Input Configuration Options [plugins-inputs-redis-options]

This plugin supports the following configuration options plus the [Common options](#plugins-inputs-redis-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`batch_count`](#plugins-inputs-redis-batch_count) | [number](/reference/configuration-file-structure.md#number) | No |
| [`command_map`](#plugins-inputs-redis-command_map) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`data_type`](#plugins-inputs-redis-data_type) | [string](/reference/configuration-file-structure.md#string), one of `["list", "channel", "pattern_channel"]` | Yes |
| [`db`](#plugins-inputs-redis-db) | [number](/reference/configuration-file-structure.md#number) | No |
| [`host`](#plugins-inputs-redis-host) | [string](/reference/configuration-file-structure.md#string) | No |
| [`path`](#plugins-inputs-redis-path) | [string](/reference/configuration-file-structure.md#string) | No |
| [`key`](#plugins-inputs-redis-key) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`password`](#plugins-inputs-redis-password) | [password](/reference/configuration-file-structure.md#password) | No |
| [`port`](#plugins-inputs-redis-port) | [number](/reference/configuration-file-structure.md#number) | No |
| [`ssl`](#plugins-inputs-redis-ssl) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`threads`](#plugins-inputs-redis-threads) | [number](/reference/configuration-file-structure.md#number) | No |
| [`timeout`](#plugins-inputs-redis-timeout) | [number](/reference/configuration-file-structure.md#number) | No |

Also see [Common options](#plugins-inputs-redis-common-options) for a list of options supported by all input plugins.

 

### `batch_count` [plugins-inputs-redis-batch_count]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `125`

The number of events to return from Redis using EVAL.


### `command_map` [plugins-inputs-redis-command_map]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* There is no default value for this setting.
* key is the default command name, value is the renamed command.

Configure renamed redis commands in the form of "oldname" ⇒ "newname". Redis allows for the renaming or disabling of commands in its protocol, see:  [https://redis.io/topics/security](https://redis.io/topics/security)


### `data_type` [plugins-inputs-redis-data_type]

* This is a required setting.
* Value can be any of: `list`, `channel`, `pattern_channel`
* There is no default value for this setting.

Specify either list or channel.  If `data_type` is `list`, then we will BLPOP the key.  If `data_type` is `channel`, then we will SUBSCRIBE to the key. If `data_type` is `pattern_channel`, then we will PSUBSCRIBE to the key.


### `db` [plugins-inputs-redis-db]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `0`

The Redis database number.


### `host` [plugins-inputs-redis-host]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"127.0.0.1"`

The hostname of your Redis server.


### `path` [plugins-inputs-redis-path]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.
* Path will override Host configuration if both specified.

The unix socket path of your Redis server.


### `key` [plugins-inputs-redis-key]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The name of a Redis list or channel.


### `password` [plugins-inputs-redis-password]

* Value type is [password](/reference/configuration-file-structure.md#password)
* There is no default value for this setting.

Password to authenticate with. There is no authentication by default.


### `port` [plugins-inputs-redis-port]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `6379`

The port to connect on.


### `ssl` [plugins-inputs-redis-ssl]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Enable SSL support.


### `threads` [plugins-inputs-redis-threads]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `1`

Number of instances of the input to start, each on its own thread. Increase from one to improve concurrency in consuming messages from Redis.

::::{note}
Increasing the number of threads when consuming from a channel will result in duplicate messages since a `SUBSCRIBE` delivers each message to all subscribers.
::::



### `timeout` [plugins-inputs-redis-timeout]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `5`

Initial connection timeout in seconds.



## Common options [plugins-inputs-redis-common-options]

These configuration options are supported by all input plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`add_field`](#plugins-inputs-redis-add_field) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`codec`](#plugins-inputs-redis-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-inputs-redis-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-inputs-redis-id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`tags`](#plugins-inputs-redis-tags) | [array](/reference/configuration-file-structure.md#array) | No |
| [`type`](#plugins-inputs-redis-type) | [string](/reference/configuration-file-structure.md#string) | No |

### `add_field` [plugins-inputs-redis-add_field]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

Add a field to an event


### `codec` [plugins-inputs-redis-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"json"`

The codec used for input data. Input codecs are a convenient method for decoding your data before it enters the input, without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-inputs-redis-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance by default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-inputs-redis-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type, for example, if you have 2 redis inputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
input {
  redis {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::



### `tags` [plugins-inputs-redis-tags]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

Add any number of arbitrary tags to your event.

This can help with processing later.


### `type` [plugins-inputs-redis-type]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a `type` field to all events handled by this input.

Types are used mainly for filter activation.

The type is stored as part of the event itself, so you can also use the type to search for it in Kibana.

If you try to set a type on an event that already has one (for example when you send an event from a shipper to an indexer) then a new input will not override the existing type. A type set at the shipper stays with that event for its life even when sent to another Logstash server.



