---
navigation_title: "loggly"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-outputs-loggly.html
---

# Loggly output plugin [plugins-outputs-loggly]


* Plugin version: v6.0.0
* Released on: 2018-07-03
* [Changelog](https://github.com/logstash-plugins/logstash-output-loggly/blob/v6.0.0/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://docs/reference/output-loggly-index.md).

## Installation [_installation_37]

For plugins not bundled by default, it is easy to install by running `bin/logstash-plugin install logstash-output-loggly`. See [Working with plugins](/reference/working-with-plugins.md) for more details.


## Getting help [_getting_help_93]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-output-loggly). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_93]

Got a loggly account? Use logstash to ship logs to Loggly!

This is most useful so you can use logstash to parse and structure your logs and ship structured, json events to your account at Loggly.

To use this, you’ll need to use a Loggly input with type *http* and *json logging* enabled.


## Loggly Output Configuration Options [plugins-outputs-loggly-options]

This plugin supports the following configuration options plus the [Common options](#plugins-outputs-loggly-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`can_retry`](#plugins-outputs-loggly-can_retry) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`convert_timestamp`](#plugins-outputs-loggly-convert_timestamp) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`host`](#plugins-outputs-loggly-host) | [string](/reference/configuration-file-structure.md#string) | No |
| [`key`](#plugins-outputs-loggly-key) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`max_event_size`](#plugins-outputs-loggly-max_event_size) | [bytes](/reference/configuration-file-structure.md#bytes) | Yes |
| [`max_payload_size`](#plugins-outputs-loggly-max_payload_size) | [bytes](/reference/configuration-file-structure.md#bytes) | Yes |
| [`proto`](#plugins-outputs-loggly-proto) | [string](/reference/configuration-file-structure.md#string) | No |
| [`proxy_host`](#plugins-outputs-loggly-proxy_host) | [string](/reference/configuration-file-structure.md#string) | No |
| [`proxy_password`](#plugins-outputs-loggly-proxy_password) | [password](/reference/configuration-file-structure.md#password) | No |
| [`proxy_port`](#plugins-outputs-loggly-proxy_port) | [number](/reference/configuration-file-structure.md#number) | No |
| [`proxy_user`](#plugins-outputs-loggly-proxy_user) | [string](/reference/configuration-file-structure.md#string) | No |
| [`retry_count`](#plugins-outputs-loggly-retry_count) | [number](/reference/configuration-file-structure.md#number) | No |
| [`tag`](#plugins-outputs-loggly-tag) | [string](/reference/configuration-file-structure.md#string) | No |

Also see [Common options](#plugins-outputs-loggly-common-options) for a list of options supported by all output plugins.

 

### `can_retry` [plugins-outputs-loggly-can_retry]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Can Retry. Setting this value true helps user to send multiple retry attempts if the first request fails


### `convert_timestamp` [plugins-outputs-loggly-convert_timestamp]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

The plugin renames Logstash’s *@timestamp* field to *timestamp* before sending, so that Loggly recognizes it automatically.

This will do nothing if your event doesn’t have a *@timestamp* field or if your event already has a *timestamp* field.

Note that the actual Logstash event is not modified by the output. This modification only happens on a copy of the event, prior to sending.


### `host` [plugins-outputs-loggly-host]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"logs-01.loggly.com"`

The hostname to send logs to. This should target the loggly http input server which is usually "logs-01.loggly.com" (Gen2 account). See the [Loggly HTTP endpoint documentation](https://www.loggly.com/docs/http-endpoint/).


### `key` [plugins-outputs-loggly-key]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The loggly http customer token to use for sending. You can find yours in "Source Setup", under "Customer Tokens".

You can use `%{{foo}}` field lookups here if you need to pull the api key from the event. This is mainly aimed at multitenant hosting providers who want to offer shipping a customer’s logs to that customer’s loggly account.


### `max_event_size` [plugins-outputs-loggly-max_event_size]

* This is a required setting.
* Value type is [bytes](/reference/configuration-file-structure.md#bytes)
* Default value is 1 Mib

The Loggly API supports event size up to 1 Mib.

You should only need to change this setting if the API limits have changed and you need to override the plugin’s behaviour.

See the [Loggly bulk API documentation](https://www.loggly.com/docs/http-bulk-endpoint/)


### `max_payload_size` [plugins-outputs-loggly-max_payload_size]

* This is a required setting.
* Value type is [bytes](/reference/configuration-file-structure.md#bytes)
* Default value is 5 Mib

The Loggly API supports API call payloads up to 5 Mib.

You should only need to change this setting if the API limits have changed and you need to override the plugin’s behaviour.

See the [Loggly bulk API documentation](https://www.loggly.com/docs/http-bulk-endpoint/)


### `proto` [plugins-outputs-loggly-proto]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"http"`

Should the log action be sent over https instead of plain http


### `proxy_host` [plugins-outputs-loggly-proxy_host]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Proxy Host


### `proxy_password` [plugins-outputs-loggly-proxy_password]

* Value type is [password](/reference/configuration-file-structure.md#password)
* Default value is `""`

Proxy Password


### `proxy_port` [plugins-outputs-loggly-proxy_port]

* Value type is [number](/reference/configuration-file-structure.md#number)
* There is no default value for this setting.

Proxy Port


### `proxy_user` [plugins-outputs-loggly-proxy_user]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Proxy Username


### `retry_count` [plugins-outputs-loggly-retry_count]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `5`

Retry count. It may be possible that the request may timeout due to slow Internet connection if such condition appears, retry_count helps in retrying request for multiple times It will try to submit request until retry_count and then halt


### `tag` [plugins-outputs-loggly-tag]

* Value type is [string](/reference/configuration-file-structure.md#string)

Loggly Tags help you to find your logs in the Loggly dashboard easily. You can search for a tag in Loggly, using `"tag:your_tag"`.

If you need to specify multiple tags here on your events, specify them as outlined in [the tag documentation](https://www.loggly.com/docs/tags/). E.g. `"tag" => "foo,bar,myApp"`.

You can also use `"tag" => "%{{somefield}},%{{another_field}}"` to take your tag values from `somefield` and `another_field` on your event. If the field doesn’t exist, no tag will be created. Helpful for leveraging [Loggly source groups](https://www.loggly.com/docs/source-groups/).



## Common options [plugins-outputs-loggly-common-options]

These configuration options are supported by all output plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`codec`](#plugins-outputs-loggly-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-outputs-loggly-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-outputs-loggly-id) | [string](/reference/configuration-file-structure.md#string) | No |

### `codec` [plugins-outputs-loggly-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for output data. Output codecs are a convenient method for encoding your data before it leaves the output without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-outputs-loggly-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance. By default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-outputs-loggly-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type. For example, if you have 2 loggly outputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
output {
  loggly {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::




