---
navigation_title: "wmi"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-inputs-wmi.html
---

# Wmi input plugin [plugins-inputs-wmi]


* Plugin version: v3.0.4
* Released on: 2018-04-06
* [Changelog](https://github.com/logstash-plugins/logstash-input-wmi/blob/v3.0.4/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://reference/input-wmi-index.md).

## Installation [_installation_19]

For plugins not bundled by default, it is easy to install by running `bin/logstash-plugin install logstash-input-wmi`. See [Working with plugins](/reference/working-with-plugins.md) for more details.


## Getting help [_getting_help_63]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-input-wmi). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_63]

Collect data from WMI query

This is useful for collecting performance metrics and other data which is accessible via WMI on a Windows host

Example:

```ruby
    input {
      wmi {
        query => "select * from Win32_Process"
        interval => 10
      }
      wmi {
        query => "select PercentProcessorTime from Win32_PerfFormattedData_PerfOS_Processor where name = '_Total'"
      }
      wmi { # Connect to a remote host
        query => "select * from Win32_Process"
        host => "MyRemoteHost"
        user => "mydomain\myuser"
        password => "Password"
      }
    }
```


## Wmi Input Configuration Options [plugins-inputs-wmi-options]

This plugin supports the following configuration options plus the [Common options](#plugins-inputs-wmi-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`host`](#plugins-inputs-wmi-host) | [string](/reference/configuration-file-structure.md#string) | No |
| [`interval`](#plugins-inputs-wmi-interval) | [number](/reference/configuration-file-structure.md#number) | No |
| [`namespace`](#plugins-inputs-wmi-namespace) | [string](/reference/configuration-file-structure.md#string) | No |
| [`password`](#plugins-inputs-wmi-password) | [password](/reference/configuration-file-structure.md#password) | No |
| [`query`](#plugins-inputs-wmi-query) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`user`](#plugins-inputs-wmi-user) | [string](/reference/configuration-file-structure.md#string) | No |

Also see [Common options](#plugins-inputs-wmi-common-options) for a list of options supported by all input plugins.

 

### `host` [plugins-inputs-wmi-host]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"localhost"`

Host to connect to ( Defaults to localhost )


### `interval` [plugins-inputs-wmi-interval]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `10`

Polling interval


### `namespace` [plugins-inputs-wmi-namespace]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"root\\cimv2"`

Namespace when doing remote connections


### `password` [plugins-inputs-wmi-password]

* Value type is [password](/reference/configuration-file-structure.md#password)
* There is no default value for this setting.

Password when doing remote connections


### `query` [plugins-inputs-wmi-query]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

WMI query


### `user` [plugins-inputs-wmi-user]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Username when doing remote connections



## Common options [plugins-inputs-wmi-common-options]

These configuration options are supported by all input plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`add_field`](#plugins-inputs-wmi-add_field) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`codec`](#plugins-inputs-wmi-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-inputs-wmi-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-inputs-wmi-id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`tags`](#plugins-inputs-wmi-tags) | [array](/reference/configuration-file-structure.md#array) | No |
| [`type`](#plugins-inputs-wmi-type) | [string](/reference/configuration-file-structure.md#string) | No |

### `add_field` [plugins-inputs-wmi-add_field]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

Add a field to an event


### `codec` [plugins-inputs-wmi-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for input data. Input codecs are a convenient method for decoding your data before it enters the input, without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-inputs-wmi-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance by default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-inputs-wmi-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type, for example, if you have 2 wmi inputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
input {
  wmi {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::



### `tags` [plugins-inputs-wmi-tags]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

Add any number of arbitrary tags to your event.

This can help with processing later.


### `type` [plugins-inputs-wmi-type]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a `type` field to all events handled by this input.

Types are used mainly for filter activation.

The type is stored as part of the event itself, so you can also use the type to search for it in Kibana.

If you try to set a type on an event that already has one (for example when you send an event from a shipper to an indexer) then a new input will not override the existing type. A type set at the shipper stays with that event for its life even when sent to another Logstash server.



