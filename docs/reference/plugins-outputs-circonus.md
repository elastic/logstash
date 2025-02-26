---
navigation_title: "circonus"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-outputs-circonus.html
---

# Circonus output plugin [plugins-outputs-circonus]


* Plugin version: v3.0.7
* Released on: 2023-05-30
* [Changelog](https://github.com/logstash-plugins/logstash-output-circonus/blob/v3.0.7/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://docs/reference/output-circonus-index.md).

## Installation [_installation_22]

For plugins not bundled by default, it is easy to install by running `bin/logstash-plugin install logstash-output-circonus`. See [Working with plugins](/reference/working-with-plugins.md) for more details.


## Getting help [_getting_help_66]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-output-circonus). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_66]

This output sends annotations to Circonus based on Logstash events.


## Circonus Output Configuration Options [plugins-outputs-circonus-options]

This plugin supports the following configuration options plus the [Common options](#plugins-outputs-circonus-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`annotation`](#plugins-outputs-circonus-annotation) | [hash](/reference/configuration-file-structure.md#hash) | Yes |
| [`api_token`](#plugins-outputs-circonus-api_token) | [password](/reference/configuration-file-structure.md#password) | Yes |
| [`app_name`](#plugins-outputs-circonus-app_name) | [string](/reference/configuration-file-structure.md#string) | Yes |

Also see [Common options](#plugins-outputs-circonus-common-options) for a list of options supported by all output plugins.

 

### `annotation` [plugins-outputs-circonus-annotation]

* This is a required setting.
* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

Annotations Registers an annotation with Circonus The only required field is `title` and `description`. `start` and `stop` will be set to the event timestamp. You can add any other optional annotation values as well. All values will be passed through `event.sprintf`

Example:

```ruby
  ["title":"Logstash event", "description":"Logstash event for %{host}"]
```

or

```ruby
  ["title":"Logstash event", "description":"Logstash event for %{host}", "parent_id", "1"]
```


### `api_token` [plugins-outputs-circonus-api_token]

* This is a required setting.
* Value type is [password](/reference/configuration-file-structure.md#password)
* There is no default value for this setting.

Your Circonus API Token


### `app_name` [plugins-outputs-circonus-app_name]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Your Circonus App name This will be passed through `event.sprintf` so variables are allowed here:

Example: `app_name => "%{{myappname}}"`



## Common options [plugins-outputs-circonus-common-options]

These configuration options are supported by all output plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`codec`](#plugins-outputs-circonus-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-outputs-circonus-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-outputs-circonus-id) | [string](/reference/configuration-file-structure.md#string) | No |

### `codec` [plugins-outputs-circonus-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for output data. Output codecs are a convenient method for encoding your data before it leaves the output without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-outputs-circonus-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance. By default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-outputs-circonus-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type. For example, if you have 2 circonus outputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
output {
  circonus {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::




