---
navigation_title: "nagios"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-outputs-nagios.html
---

# Nagios output plugin [plugins-outputs-nagios]


* Plugin version: v3.0.6
* Released on: 2018-04-06
* [Changelog](https://github.com/logstash-plugins/logstash-output-nagios/blob/v3.0.6/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://docs/reference/output-nagios-index.md).

## Getting help [_getting_help_97]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-output-nagios). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_97]

The Nagios output is used for sending passive check results to Nagios via the Nagios command file. This output currently supports Nagios 3.

For this output to work, your event *must* have the following Logstash event fields:

* `nagios_host`
* `nagios_service`

These Logstash event fields are supported, but optional:

* `nagios_annotation`
* `nagios_level` (overrides `nagios_level` configuration option)

There are two configuration options:

* `commandfile` - The location of the Nagios external command file. Defaults to */var/lib/nagios3/rw/nagios.cmd*
* `nagios_level` - Specifies the level of the check to be sent. Defaults to CRITICAL and can be overriden by setting the "nagios_level" field to one of "OK", "WARNING", "CRITICAL", or "UNKNOWN"

    ```ruby
        output{
          if [message] =~ /(error|ERROR|CRITICAL)/ {
            nagios {
              # your config here
            }
          }
        }
    ```



## Nagios Output Configuration Options [plugins-outputs-nagios-options]

This plugin supports the following configuration options plus the [Common options](#plugins-outputs-nagios-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`commandfile`](#plugins-outputs-nagios-commandfile) | <<,>> | No |
| [`nagios_level`](#plugins-outputs-nagios-nagios_level) | [string](/reference/configuration-file-structure.md#string), one of `["0", "1", "2", "3"]` | No |

Also see [Common options](#plugins-outputs-nagios-common-options) for a list of options supported by all output plugins.

 

### `commandfile` [plugins-outputs-nagios-commandfile]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"/var/lib/nagios3/rw/nagios.cmd"`

The full path to your Nagios command file.


### `nagios_level` [plugins-outputs-nagios-nagios_level]

* Value can be any of: `0`, `1`, `2`, `3`
* Default value is `"2"`

The Nagios check level. Should be one of 0=OK, 1=WARNING, 2=CRITICAL, 3=UNKNOWN. Defaults to 2 - CRITICAL.



## Common options [plugins-outputs-nagios-common-options]

These configuration options are supported by all output plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`codec`](#plugins-outputs-nagios-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-outputs-nagios-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-outputs-nagios-id) | [string](/reference/configuration-file-structure.md#string) | No |

### `codec` [plugins-outputs-nagios-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for output data. Output codecs are a convenient method for encoding your data before it leaves the output without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-outputs-nagios-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance. By default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-outputs-nagios-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type. For example, if you have 2 nagios outputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
output {
  nagios {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::




