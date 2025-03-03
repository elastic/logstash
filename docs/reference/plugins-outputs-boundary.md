---
navigation_title: "boundary"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-outputs-boundary.html
---

# Boundary output plugin [plugins-outputs-boundary]


* Plugin version: v3.0.6
* Released on: 2023-05-30
* [Changelog](https://github.com/logstash-plugins/logstash-output-boundary/blob/v3.0.6/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://reference/output-boundary-index.md).

## Installation [_installation_21]

For plugins not bundled by default, it is easy to install by running `bin/logstash-plugin install logstash-output-boundary`. See [Working with plugins](/reference/working-with-plugins.md) for more details.


## Getting help [_getting_help_65]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-output-boundary). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_65]

This output lets you send annotations to Boundary based on Logstash events

Note that since Logstash maintains no state these will be one-shot events

By default the start and stop time will be the event timestamp


## Boundary Output Configuration Options [plugins-outputs-boundary-options]

This plugin supports the following configuration options plus the [Common options](#plugins-outputs-boundary-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`api_key`](#plugins-outputs-boundary-api_key) | [password](/reference/configuration-file-structure.md#password) | Yes |
| [`auto`](#plugins-outputs-boundary-auto) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`bsubtype`](#plugins-outputs-boundary-bsubtype) | [string](/reference/configuration-file-structure.md#string) | No |
| [`btags`](#plugins-outputs-boundary-btags) | [array](/reference/configuration-file-structure.md#array) | No |
| [`btype`](#plugins-outputs-boundary-btype) | [string](/reference/configuration-file-structure.md#string) | No |
| [`end_time`](#plugins-outputs-boundary-end_time) | [string](/reference/configuration-file-structure.md#string) | No |
| [`org_id`](#plugins-outputs-boundary-org_id) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`start_time`](#plugins-outputs-boundary-start_time) | [string](/reference/configuration-file-structure.md#string) | No |

Also see [Common options](#plugins-outputs-boundary-common-options) for a list of options supported by all output plugins.

 

### `api_key` [plugins-outputs-boundary-api_key]

* This is a required setting.
* Value type is [password](/reference/configuration-file-structure.md#password)
* There is no default value for this setting.

Your Boundary API key


### `auto` [plugins-outputs-boundary-auto]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Auto If set to true, logstash will try to pull boundary fields out of the event. Any field explicitly set by config options will override these. `['type', 'subtype', 'creation_time', 'end_time', 'links', 'tags', 'loc']`


### `bsubtype` [plugins-outputs-boundary-bsubtype]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Sub-Type


### `btags` [plugins-outputs-boundary-btags]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

Tags Set any custom tags for this event Default are the Logstash tags if any


### `btype` [plugins-outputs-boundary-btype]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Type


### `end_time` [plugins-outputs-boundary-end_time]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

End time Override the stop time Note that Boundary requires this to be seconds since epoch If overriding, it is your responsibility to type this correctly By default this is set to `event.get("@timestamp").to_i`


### `org_id` [plugins-outputs-boundary-org_id]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Your Boundary Org ID


### `start_time` [plugins-outputs-boundary-start_time]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Start time Override the start time Note that Boundary requires this to be seconds since epoch If overriding, it is your responsibility to type this correctly By default this is set to `event.get("@timestamp").to_i`



## Common options [plugins-outputs-boundary-common-options]

These configuration options are supported by all output plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`codec`](#plugins-outputs-boundary-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-outputs-boundary-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-outputs-boundary-id) | [string](/reference/configuration-file-structure.md#string) | No |

### `codec` [plugins-outputs-boundary-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for output data. Output codecs are a convenient method for encoding your data before it leaves the output without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-outputs-boundary-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance. By default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-outputs-boundary-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type. For example, if you have 2 boundary outputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
output {
  boundary {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::




