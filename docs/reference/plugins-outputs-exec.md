---
navigation_title: "exec"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-outputs-exec.html
---

# Exec output plugin [plugins-outputs-exec]


* Plugin version: v3.1.4
* Released on: 2018-04-06
* [Changelog](https://github.com/logstash-plugins/logstash-output-exec/blob/v3.1.4/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://reference/output-exec-index.md).

## Installation [_installation_26]

For plugins not bundled by default, it is easy to install by running `bin/logstash-plugin install logstash-output-exec`. See [Working with plugins](/reference/working-with-plugins.md) for more details.


## Getting help [_getting_help_76]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-output-exec). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_76]

The exec output will run a command for each event received. Ruby’s `system()` function will be used, i.e. the command string will be passed to a shell. You can use `%{{name}}` and other dynamic strings in the command to pass select fields from the event to the child process. Example:

```ruby
    output {
      if [type] == "abuse" {
        exec {
          command => "iptables -A INPUT -s %{clientip} -j DROP"
        }
      }
    }
```

::::{warning}
If you want it non-blocking you should use `&` or `dtach` or other such techniques. There is no timeout for the commands being run so misbehaving commands could otherwise stall the Logstash pipeline indefinitely.
::::


::::{warning}
Exercise great caution with `%{{name}}` field placeholders. The contents of the field will be included verbatim without any sanitization, i.e. any shell metacharacters from the field values will be passed straight to the shell.
::::



## Exec Output Configuration Options [plugins-outputs-exec-options]

This plugin supports the following configuration options plus the [Common options](#plugins-outputs-exec-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`command`](#plugins-outputs-exec-command) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`quiet`](#plugins-outputs-exec-quiet) | [boolean](/reference/configuration-file-structure.md#boolean) | No |

Also see [Common options](#plugins-outputs-exec-common-options) for a list of options supported by all output plugins.

 

### `command` [plugins-outputs-exec-command]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Command line to execute via subprocess. Use `dtach` or `screen` to make it non blocking. This value can include `%{{name}}` and other dynamic strings.


### `quiet` [plugins-outputs-exec-quiet]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

display the result of the command to the terminal



## Common options [plugins-outputs-exec-common-options]

These configuration options are supported by all output plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`codec`](#plugins-outputs-exec-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-outputs-exec-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-outputs-exec-id) | [string](/reference/configuration-file-structure.md#string) | No |

### `codec` [plugins-outputs-exec-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for output data. Output codecs are a convenient method for encoding your data before it leaves the output without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-outputs-exec-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance. By default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-outputs-exec-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type. For example, if you have 2 exec outputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
output {
  exec {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::




