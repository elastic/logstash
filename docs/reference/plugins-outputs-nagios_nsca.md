---
navigation_title: "nagios_nsca"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-outputs-nagios_nsca.html
---

# Nagios_nsca output plugin [plugins-outputs-nagios_nsca]


* Plugin version: v3.0.7
* Released on: 2021-09-20
* [Changelog](https://github.com/logstash-plugins/logstash-output-nagios_nsca/blob/v3.0.7/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://reference/output-nagios_nsca-index.md).

## Installation [_installation_40]

For plugins not bundled by default, it is easy to install by running `bin/logstash-plugin install logstash-output-nagios_nsca`. See [Working with plugins](/reference/working-with-plugins.md) for more details.


## Getting help [_getting_help_98]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-output-nagios_nsca). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_98]

The nagios_nsca output is used for sending passive check results to Nagios through the NSCA protocol.

This is useful if your Nagios server is not the same as the source host from where you want to send logs or alerts. If you only have one server, this output is probably overkill # for you, take a look at the *nagios* output instead.

Here is a sample config using the nagios_nsca output:

```ruby
    output {
      nagios_nsca {
        # specify the hostname or ip of your nagios server
        host => "nagios.example.com"
```

```
    # specify the port to connect to
    port => 5667
  }
}
```

## Nagios_nsca Output Configuration Options [plugins-outputs-nagios_nsca-options]

This plugin supports the following configuration options plus the [Common options](#plugins-outputs-nagios_nsca-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`host`](#plugins-outputs-nagios_nsca-host) | [string](/reference/configuration-file-structure.md#string) | No |
| [`message_format`](#plugins-outputs-nagios_nsca-message_format) | [string](/reference/configuration-file-structure.md#string) | No |
| [`nagios_host`](#plugins-outputs-nagios_nsca-nagios_host) | [string](/reference/configuration-file-structure.md#string) | No |
| [`nagios_service`](#plugins-outputs-nagios_nsca-nagios_service) | [string](/reference/configuration-file-structure.md#string) | No |
| [`nagios_status`](#plugins-outputs-nagios_nsca-nagios_status) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`port`](#plugins-outputs-nagios_nsca-port) | [number](/reference/configuration-file-structure.md#number) | No |
| [`send_nsca_bin`](#plugins-outputs-nagios_nsca-send_nsca_bin) | [string](/reference/configuration-file-structure.md#string) | No |
| [`send_nsca_config`](#plugins-outputs-nagios_nsca-send_nsca_config) | a valid filesystem path | No |

Also see [Common options](#plugins-outputs-nagios_nsca-common-options) for a list of options supported by all output plugins.

 

### `host` [plugins-outputs-nagios_nsca-host]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"localhost"`

The nagios host or IP to send logs to. It should have a NSCA daemon running.


### `message_format` [plugins-outputs-nagios_nsca-message_format]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"%{@timestamp} %{{host}}: %{{message}}"`

The format to use when writing events to nagios. This value supports any string and can include `%{{name}}` and other dynamic strings.


### `nagios_host` [plugins-outputs-nagios_nsca-nagios_host]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `%{{host}}`

The nagios *host* you want to submit a passive check result to. This parameter accepts interpolation, e.g. you can use `@source_host` or other logstash internal variables.


### `nagios_service` [plugins-outputs-nagios_nsca-nagios_service]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"LOGSTASH"`

The nagios *service* you want to submit a passive check result to. This parameter accepts interpolation, e.g. you can use `@source_host` or other logstash internal variables.


### `nagios_status` [plugins-outputs-nagios_nsca-nagios_status]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The status to send to nagios. Should be 0 = OK, 1 = WARNING, 2 = CRITICAL, 3 = UNKNOWN


### `port` [plugins-outputs-nagios_nsca-port]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `5667`

The port where the NSCA daemon on the nagios host listens.


### `send_nsca_bin` [plugins-outputs-nagios_nsca-send_nsca_bin]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"/usr/sbin/send_nsca"`

The path to the *send_nsca* binary on the local host.


### `send_nsca_config` [plugins-outputs-nagios_nsca-send_nsca_config]

* Value type is [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting.

The path to the send_nsca config file on the local host. Leave blank if you don’t want to provide a config file.



## Common options [plugins-outputs-nagios_nsca-common-options]

These configuration options are supported by all output plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`codec`](#plugins-outputs-nagios_nsca-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-outputs-nagios_nsca-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-outputs-nagios_nsca-id) | [string](/reference/configuration-file-structure.md#string) | No |

### `codec` [plugins-outputs-nagios_nsca-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for output data. Output codecs are a convenient method for encoding your data before it leaves the output without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-outputs-nagios_nsca-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance. By default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-outputs-nagios_nsca-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type. For example, if you have 2 nagios_nsca outputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
output {
  nagios_nsca {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::




