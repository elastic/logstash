---
navigation_title: "exec"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-inputs-exec.html
---

# Exec input plugin [plugins-inputs-exec]


* Plugin version: v3.6.0
* Released on: 2022-06-15
* [Changelog](https://github.com/logstash-plugins/logstash-input-exec/blob/v3.6.0/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://reference/input-exec-index.md).

## Getting help [_getting_help_16]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-input-exec). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_17]

Periodically run a shell command and capture the whole output as an event.

::::{note}
* The `command` field of this event will be the command run.
* The `message` field of this event will be the entire stdout of the command.

::::


::::{important}
The exec input ultimately uses `fork` to spawn a child process. Using fork duplicates the parent process address space (in our case, **logstash and the JVM**); this is mitigated with OS copy-on-write but ultimately you can end up allocating lots of memory just for a "simple" executable. If the exec input fails with errors like `ENOMEM: Cannot allocate memory` it is an indication that there is not enough non-JVM-heap physical memory to perform the fork.
::::


Example:

```ruby
input {
  exec {
    command => "echo 'hi!'"
    interval => 30
  }
}
```

This will execute `echo` command every 30 seconds.


## Compatibility with the Elastic Common Schema (ECS) [plugins-inputs-exec-ecs]

This plugin adds metadata about the event’s source, and can be configured to do so in an [ECS-compatible](ecs://reference/index.md) way with [`ecs_compatibility`](#plugins-inputs-exec-ecs_compatibility). This metadata is added after the event has been decoded by the appropriate codec, and will not overwrite existing values.

| ECS Disabled | ECS v1 , v8 | Description |
| --- | --- | --- |
| `host` | `[host][name]` | The name of the {{ls}} host that processed the event |
| `command` | `[process][command_line]` | The command run by the plugin |
| `[@metadata][exit_status]` | `[process][exit_code]` | The exit code of the process |
|  —  | `[@metadata][input][exec][process][elapsed_time]` | The elapsed time the command took to run in nanoseconds |
| `[@metadata][duration]` |  —  | Command duration in seconds as a floating point number (deprecated) |


## Exec Input configuration options [plugins-inputs-exec-options]

This plugin supports the following configuration options plus the [Common options](#plugins-inputs-exec-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`command`](#plugins-inputs-exec-command) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`ecs_compatibility`](#plugins-inputs-exec-ecs_compatibility) | [string](/reference/configuration-file-structure.md#string) | No |
| [`interval`](#plugins-inputs-exec-interval) | [number](/reference/configuration-file-structure.md#number) | No |
| [`schedule`](#plugins-inputs-exec-schedule) | [string](/reference/configuration-file-structure.md#string) | No |

Also see [Common options](#plugins-inputs-exec-common-options) for a list of options supported by all input plugins.

 

### `command` [plugins-inputs-exec-command]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Command to run. For example, `uptime`


### `ecs_compatibility` [plugins-inputs-exec-ecs_compatibility]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Supported values are:

    * `disabled`: uses backwards compatible field names, such as `[host]`
    * `v1`, `v8`: uses fields that are compatible with ECS, such as `[host][name]`


Controls this plugin’s compatibility with the [Elastic Common Schema (ECS)][Elastic Common Schema (ECS)](ecs://reference/index.md)). See [Compatibility with the Elastic Common Schema (ECS)](#plugins-inputs-exec-ecs) for detailed information.

**Sample output: ECS enabled**

```ruby
{
    "message" => "hi!\n",
    "process" => {
        "command_line" => "echo 'hi!'",
        "exit_code" => 0
    },
    "host" => {
        "name" => "deus-ex-machina"
    },

    "@metadata" => {
        "input" => {
            "exec" => {
                "process" => {
                    "elapsed_time"=>3042
                }
            }
        }
    }
}
```

**Sample output: ECS disabled**

```ruby
{
    "message" => "hi!\n",
    "command" => "echo 'hi!'",
    "host" => "deus-ex-machina",

    "@metadata" => {
        "exit_status" => 0,
        "duration" => 0.004388
    }
}
```


### `interval` [plugins-inputs-exec-interval]

* Value type is [number](/reference/configuration-file-structure.md#number)
* There is no default value for this setting.

Interval to run the command. Value is in seconds.

Either `interval` or `schedule` option must be defined.


### `schedule` [plugins-inputs-exec-schedule]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Schedule of when to periodically run command.

This scheduling syntax is powered by [rufus-scheduler](https://github.com/jmettraux/rufus-scheduler). The syntax is cron-like with some extensions specific to Rufus (e.g. timezone support).

Examples:

|     |     |
| --- | --- |
| `* 5 * 1-3 *` | will execute every minute of 5am every day of January through March. |
| `0 * * * *` | will execute on the 0th minute of every hour every day. |
| `0 6 * * * America/Chicago` | will execute at 6:00am (UTC/GMT -5) every day. |

Further documentation describing this syntax can be found [here](https://github.com/jmettraux/rufus-scheduler#parsing-cronlines-and-time-strings).

Either `interval` or `schedule` option must be defined.



## Common options [plugins-inputs-exec-common-options]

These configuration options are supported by all input plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`add_field`](#plugins-inputs-exec-add_field) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`codec`](#plugins-inputs-exec-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-inputs-exec-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-inputs-exec-id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`tags`](#plugins-inputs-exec-tags) | [array](/reference/configuration-file-structure.md#array) | No |
| [`type`](#plugins-inputs-exec-type) | [string](/reference/configuration-file-structure.md#string) | No |

### `add_field` [plugins-inputs-exec-add_field]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

Add a field to an event


### `codec` [plugins-inputs-exec-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for input data. Input codecs are a convenient method for decoding your data before it enters the input, without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-inputs-exec-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance by default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-inputs-exec-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type, for example, if you have 2 exec inputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
input {
  exec {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::



### `tags` [plugins-inputs-exec-tags]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

Add any number of arbitrary tags to your event.

This can help with processing later.


### `type` [plugins-inputs-exec-type]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a `type` field to all events handled by this input.

Types are used mainly for filter activation.

The type is stored as part of the event itself, so you can also use the type to search for it in Kibana.

If you try to set a type on an event that already has one (for example when you send an event from a shipper to an indexer) then a new input will not override the existing type. A type set at the shipper stays with that event for its life even when sent to another Logstash server.
