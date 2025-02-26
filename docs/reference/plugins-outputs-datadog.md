---
navigation_title: "datadog"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-outputs-datadog.html
---

# Datadog output plugin [plugins-outputs-datadog]


* Plugin version: v3.0.6
* Released on: 2023-05-31
* [Changelog](https://github.com/logstash-plugins/logstash-output-datadog/blob/v3.0.6/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://docs/reference/output-datadog-index.md).

## Installation [_installation_23]

For plugins not bundled by default, it is easy to install by running `bin/logstash-plugin install logstash-output-datadog`. See [Working with plugins](/reference/working-with-plugins.md) for more details.


## Getting help [_getting_help_69]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-output-datadog). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_69]

This output sends events to DataDogHQ based on Logstash events.

Note that since Logstash maintains no state these will be one-shot events


## Datadog Output Configuration Options [plugins-outputs-datadog-options]

This plugin supports the following configuration options plus the [Common options](#plugins-outputs-datadog-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`alert_type`](#plugins-outputs-datadog-alert_type) | [string](/reference/configuration-file-structure.md#string), one of `["info", "error", "warning", "success"]` | No |
| [`api_key`](#plugins-outputs-datadog-api_key) | [password](/reference/configuration-file-structure.md#password) | Yes |
| [`date_happened`](#plugins-outputs-datadog-date_happened) | [string](/reference/configuration-file-structure.md#string) | No |
| [`dd_tags`](#plugins-outputs-datadog-dd_tags) | [array](/reference/configuration-file-structure.md#array) | No |
| [`priority`](#plugins-outputs-datadog-priority) | [string](/reference/configuration-file-structure.md#string), one of `["normal", "low"]` | No |
| [`source_type_name`](#plugins-outputs-datadog-source_type_name) | [string](/reference/configuration-file-structure.md#string), one of `["nagios", "hudson", "jenkins", "user", "my apps", "feed", "chef", "puppet", "git", "bitbucket", "fabric", "capistrano"]` | No |
| [`text`](#plugins-outputs-datadog-text) | [string](/reference/configuration-file-structure.md#string) | No |
| [`title`](#plugins-outputs-datadog-title) | [string](/reference/configuration-file-structure.md#string) | No |

Also see [Common options](#plugins-outputs-datadog-common-options) for a list of options supported by all output plugins.

 

### `alert_type` [plugins-outputs-datadog-alert_type]

* Value can be any of: `info`, `error`, `warning`, `success`
* There is no default value for this setting.

Alert type


### `api_key` [plugins-outputs-datadog-api_key]

* This is a required setting.
* Value type is [password](/reference/configuration-file-structure.md#password)
* There is no default value for this setting.

Your DatadogHQ API key


### `date_happened` [plugins-outputs-datadog-date_happened]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Date Happened


### `dd_tags` [plugins-outputs-datadog-dd_tags]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

Tags Set any custom tags for this event Default are the Logstash tags if any


### `priority` [plugins-outputs-datadog-priority]

* Value can be any of: `normal`, `low`
* There is no default value for this setting.

Priority


### `source_type_name` [plugins-outputs-datadog-source_type_name]

* Value can be any of: `nagios`, `hudson`, `jenkins`, `user`, `my apps`, `feed`, `chef`, `puppet`, `git`, `bitbucket`, `fabric`, `capistrano`
* Default value is `"my apps"`

Source type name


### `text` [plugins-outputs-datadog-text]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"%{{message}}"`

Text


### `title` [plugins-outputs-datadog-title]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"Logstash event for %{{host}}"`

Title



## Common options [plugins-outputs-datadog-common-options]

These configuration options are supported by all output plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`codec`](#plugins-outputs-datadog-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-outputs-datadog-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-outputs-datadog-id) | [string](/reference/configuration-file-structure.md#string) | No |

### `codec` [plugins-outputs-datadog-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for output data. Output codecs are a convenient method for encoding your data before it leaves the output without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-outputs-datadog-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance. By default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-outputs-datadog-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type. For example, if you have 2 datadog outputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
output {
  datadog {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::




