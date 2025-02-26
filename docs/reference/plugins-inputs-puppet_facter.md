---
navigation_title: "puppet_facter"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-inputs-puppet_facter.html
---

# Puppet_facter input plugin [plugins-inputs-puppet_facter]


* Plugin version: v3.0.4
* Released on: 2018-04-06
* [Changelog](https://github.com/logstash-plugins/logstash-input-puppet_facter/blob/v3.0.4/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://docs/reference/input-puppet_facter-index.md).

## Installation [_installation_10]

For plugins not bundled by default, it is easy to install by running `bin/logstash-plugin install logstash-input-puppet_facter`. See [Working with plugins](/reference/working-with-plugins.md) for more details.


## Getting help [_getting_help_42]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-input-puppet_facter). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_42]

Connects to a puppet server and requests facts


## Puppet_facter Input Configuration Options [plugins-inputs-puppet_facter-options]

This plugin supports the following configuration options plus the [Common options](#plugins-inputs-puppet_facter-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`environment`](#plugins-inputs-puppet_facter-environment) | [string](/reference/configuration-file-structure.md#string) | No |
| [`host`](#plugins-inputs-puppet_facter-host) | [string](/reference/configuration-file-structure.md#string) | No |
| [`interval`](#plugins-inputs-puppet_facter-interval) | [number](/reference/configuration-file-structure.md#number) | No |
| [`port`](#plugins-inputs-puppet_facter-port) | [number](/reference/configuration-file-structure.md#number) | No |
| [`private_key`](#plugins-inputs-puppet_facter-private_key) | a valid filesystem path | No |
| [`public_key`](#plugins-inputs-puppet_facter-public_key) | a valid filesystem path | No |
| [`ssl`](#plugins-inputs-puppet_facter-ssl) | [boolean](/reference/configuration-file-structure.md#boolean) | No |

Also see [Common options](#plugins-inputs-puppet_facter-common-options) for a list of options supported by all input plugins.

 

### `environment` [plugins-inputs-puppet_facter-environment]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"production"`


### `host` [plugins-inputs-puppet_facter-host]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"0.0.0.0"`


### `interval` [plugins-inputs-puppet_facter-interval]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `600`


### `port` [plugins-inputs-puppet_facter-port]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `8140`


### `private_key` [plugins-inputs-puppet_facter-private_key]

* Value type is [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting.


### `public_key` [plugins-inputs-puppet_facter-public_key]

* Value type is [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting.


### `ssl` [plugins-inputs-puppet_facter-ssl]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`



## Common options [plugins-inputs-puppet_facter-common-options]

These configuration options are supported by all input plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`add_field`](#plugins-inputs-puppet_facter-add_field) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`codec`](#plugins-inputs-puppet_facter-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-inputs-puppet_facter-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-inputs-puppet_facter-id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`tags`](#plugins-inputs-puppet_facter-tags) | [array](/reference/configuration-file-structure.md#array) | No |
| [`type`](#plugins-inputs-puppet_facter-type) | [string](/reference/configuration-file-structure.md#string) | No |

### `add_field` [plugins-inputs-puppet_facter-add_field]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

Add a field to an event


### `codec` [plugins-inputs-puppet_facter-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for input data. Input codecs are a convenient method for decoding your data before it enters the input, without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-inputs-puppet_facter-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance by default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-inputs-puppet_facter-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type, for example, if you have 2 puppet_facter inputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
input {
  puppet_facter {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::



### `tags` [plugins-inputs-puppet_facter-tags]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

Add any number of arbitrary tags to your event.

This can help with processing later.


### `type` [plugins-inputs-puppet_facter-type]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a `type` field to all events handled by this input.

Types are used mainly for filter activation.

The type is stored as part of the event itself, so you can also use the type to search for it in Kibana.

If you try to set a type on an event that already has one (for example when you send an event from a shipper to an indexer) then a new input will not override the existing type. A type set at the shipper stays with that event for its life even when sent to another Logstash server.



