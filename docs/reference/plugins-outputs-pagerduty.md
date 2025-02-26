---
navigation_title: "pagerduty"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-outputs-pagerduty.html
---

# Pagerduty output plugin [plugins-outputs-pagerduty]


* Plugin version: v3.0.9
* Released on: 2020-01-27
* [Changelog](https://github.com/logstash-plugins/logstash-output-pagerduty/blob/v3.0.9/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://docs/reference/output-pagerduty-index.md).

## Installation [_installation_42]

For plugins not bundled by default, it is easy to install by running `bin/logstash-plugin install logstash-output-pagerduty`. See [Working with plugins](/reference/working-with-plugins.md) for more details.


## Getting help [_getting_help_100]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-output-pagerduty). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_100]

The PagerDuty output will send notifications based on pre-configured services and escalation policies. Logstash can send "trigger", "acknowledge" and "resolve" event types. In addition, you may configure custom descriptions and event details. The only required field is the PagerDuty "Service API Key", which can be found on the service’s web page on pagerduty.com. In the default case, the description and event details will be populated by Logstash, using `message`, `timestamp` and `host` data.


## Pagerduty Output Configuration Options [plugins-outputs-pagerduty-options]

This plugin supports the following configuration options plus the [Common options](#plugins-outputs-pagerduty-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`description`](#plugins-outputs-pagerduty-description) | [string](/reference/configuration-file-structure.md#string) | No |
| [`details`](#plugins-outputs-pagerduty-details) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`event_type`](#plugins-outputs-pagerduty-event_type) | [string](/reference/configuration-file-structure.md#string), one of `["trigger", "acknowledge", "resolve"]` | No |
| [`incident_key`](#plugins-outputs-pagerduty-incident_key) | [string](/reference/configuration-file-structure.md#string) | No |
| [`pdurl`](#plugins-outputs-pagerduty-pdurl) | [string](/reference/configuration-file-structure.md#string) | No |
| [`service_key`](#plugins-outputs-pagerduty-service_key) | [string](/reference/configuration-file-structure.md#string) | Yes |

Also see [Common options](#plugins-outputs-pagerduty-common-options) for a list of options supported by all output plugins.

 

### `description` [plugins-outputs-pagerduty-description]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"Logstash event for %{{host}}"`

Custom description


### `details` [plugins-outputs-pagerduty-details]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{"timestamp"=>"%{@timestamp}", "message"=>"%{{message}}"}`

The event details. These might be data from the Logstash event fields you wish to include. Tags are automatically included if detected so there is no need to explicitly add them here.


### `event_type` [plugins-outputs-pagerduty-event_type]

* Value can be any of: `trigger`, `acknowledge`, `resolve`
* Default value is `"trigger"`

Event type


### `incident_key` [plugins-outputs-pagerduty-incident_key]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"logstash/%{{host}}/%{{type}}"`

The service key to use. You’ll need to set this up in PagerDuty beforehand.


### `pdurl` [plugins-outputs-pagerduty-pdurl]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"https://events.pagerduty.com/generic/2010-04-15/create_event.json"`

PagerDuty API URL. You shouldn’t need to change this, but is included to allow for flexibility should PagerDuty iterate the API and Logstash hasn’t been updated yet.


### `service_key` [plugins-outputs-pagerduty-service_key]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The PagerDuty Service API Key



## Common options [plugins-outputs-pagerduty-common-options]

These configuration options are supported by all output plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`codec`](#plugins-outputs-pagerduty-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-outputs-pagerduty-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-outputs-pagerduty-id) | [string](/reference/configuration-file-structure.md#string) | No |

### `codec` [plugins-outputs-pagerduty-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for output data. Output codecs are a convenient method for encoding your data before it leaves the output without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-outputs-pagerduty-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance. By default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-outputs-pagerduty-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type. For example, if you have 2 pagerduty outputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
output {
  pagerduty {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::




