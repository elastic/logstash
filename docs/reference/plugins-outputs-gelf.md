---
navigation_title: "gelf"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-outputs-gelf.html
---

# Gelf output plugin [plugins-outputs-gelf]


* Plugin version: v3.1.7
* Released on: 2018-04-06
* [Changelog](https://github.com/logstash-plugins/logstash-output-gelf/blob/v3.1.7/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://reference/output-gelf-index.md).

## Installation [_installation_28]

For plugins not bundled by default, it is easy to install by running `bin/logstash-plugin install logstash-output-gelf`. See [Working with plugins](/reference/working-with-plugins.md) for more details.


## Getting help [_getting_help_79]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-output-gelf). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_79]

This output generates messages in GELF format. This is most useful if you want to use Logstash to output events to Graylog2.

More information at [The Graylog2 GELF specs page](http://docs.graylog.org/en/2.3/pages/gelf.md#gelf-payload-specification)


## Gelf Output Configuration Options [plugins-outputs-gelf-options]

This plugin supports the following configuration options plus the [Common options](#plugins-outputs-gelf-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`chunksize`](#plugins-outputs-gelf-chunksize) | [number](/reference/configuration-file-structure.md#number) | No |
| [`custom_fields`](#plugins-outputs-gelf-custom_fields) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`full_message`](#plugins-outputs-gelf-full_message) | [string](/reference/configuration-file-structure.md#string) | No |
| [`host`](#plugins-outputs-gelf-host) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`ignore_metadata`](#plugins-outputs-gelf-ignore_metadata) | [array](/reference/configuration-file-structure.md#array) | No |
| [`level`](#plugins-outputs-gelf-level) | [array](/reference/configuration-file-structure.md#array) | No |
| [`port`](#plugins-outputs-gelf-port) | [number](/reference/configuration-file-structure.md#number) | No |
| [`protocol`](#plugins-outputs-gelf-protocol) | [string](/reference/configuration-file-structure.md#string) | No |
| [`sender`](#plugins-outputs-gelf-sender) | [string](/reference/configuration-file-structure.md#string) | No |
| [`ship_metadata`](#plugins-outputs-gelf-ship_metadata) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`ship_tags`](#plugins-outputs-gelf-ship_tags) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`short_message`](#plugins-outputs-gelf-short_message) | [string](/reference/configuration-file-structure.md#string) | No |

Also see [Common options](#plugins-outputs-gelf-common-options) for a list of options supported by all output plugins.

 

### `chunksize` [plugins-outputs-gelf-chunksize]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `1420`

The chunksize. You usually don’t need to change this.


### `custom_fields` [plugins-outputs-gelf-custom_fields]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

The GELF custom field mappings. GELF supports arbitrary attributes as custom fields. This exposes that. Exclude the `_` portion of the field name e.g. `custom_fields => ['foo_field', 'some_value']` sets `_foo_field` = `some_value`.


### `full_message` [plugins-outputs-gelf-full_message]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"%{{message}}"`

The GELF full message. Dynamic values like `%{{foo}}` are permitted here.


### `host` [plugins-outputs-gelf-host]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Graylog2 server IP address or hostname.


### `ignore_metadata` [plugins-outputs-gelf-ignore_metadata]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `["@timestamp", "@version", "severity", "host", "source_host", "source_path", "short_message"]`

Ignore these fields when `ship_metadata` is set. Typically this lists the fields used in dynamic values for GELF fields.


### `level` [plugins-outputs-gelf-level]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `["%{{severity}}", "INFO"]`

The GELF message level. Dynamic values like `%{{level}}` are permitted here; useful if you want to parse the *log level* from an event and use that as the GELF level/severity.

Values here can be integers [0..7] inclusive or any of "debug", "info", "warn", "error", "fatal" (case insensitive). Single-character versions of these are also valid, "d", "i", "w", "e", "f", "u" The following additional severity\_labels from Logstash’s  syslog\_pri filter are accepted: "emergency", "alert", "critical",  "warning", "notice", and "informational".


### `port` [plugins-outputs-gelf-port]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `12201`

Graylog2 server port number.


### `protocol` [plugins-outputs-gelf-protocol]

By default, this plugin outputs via the UDP transfer protocol, but can be configured to use TCP instead.

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"UDP"`

Values here can be either "TCP" or "UDP".


### `sender` [plugins-outputs-gelf-sender]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `%{{host}}`

Allow overriding of the GELF `sender` field. This is useful if you want to use something other than the event’s source host as the "sender" of an event. A common case for this is using the application name instead of the hostname.


### `ship_metadata` [plugins-outputs-gelf-ship_metadata]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Should Logstash ship metadata within event object? This will cause Logstash to ship any fields in the event (such as those created by grok) in the GELF messages. These will be sent as underscored "additional fields".


### `ship_tags` [plugins-outputs-gelf-ship_tags]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Ship tags within events. This will cause Logstash to ship the tags of an event as the field `\_tags`.


### `short_message` [plugins-outputs-gelf-short_message]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"short_message"`

The GELF short message field name. If the field does not exist or is empty, the event message is taken instead.



## Common options [plugins-outputs-gelf-common-options]

These configuration options are supported by all output plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`codec`](#plugins-outputs-gelf-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-outputs-gelf-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-outputs-gelf-id) | [string](/reference/configuration-file-structure.md#string) | No |

### `codec` [plugins-outputs-gelf-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for output data. Output codecs are a convenient method for encoding your data before it leaves the output without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-outputs-gelf-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance. By default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-outputs-gelf-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type. For example, if you have 2 gelf outputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
output {
  gelf {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::




