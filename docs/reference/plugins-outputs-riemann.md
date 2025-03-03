---
navigation_title: "riemann"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-outputs-riemann.html
---

# Riemann output plugin [plugins-outputs-riemann]


* Plugin version: v3.0.7
* Released on: 2020-07-15
* [Changelog](https://github.com/logstash-plugins/logstash-output-riemann/blob/v3.0.7/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://reference/output-riemann-index.md).

## Installation [_installation_45]

For plugins not bundled by default, it is easy to install by running `bin/logstash-plugin install logstash-output-riemann`. See [Working with plugins](/reference/working-with-plugins.md) for more details.


## Getting help [_getting_help_106]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-output-riemann). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_106]

Riemann is a network event stream processing system.

While Riemann is very similar conceptually to Logstash, it has much more in terms of being a monitoring system replacement.

Riemann is used in Logstash much like statsd or other metric-related outputs

You can learn about Riemann here:

* [http://riemann.io/](http://riemann.io/)

You can see the author talk about it here:

* [http://vimeo.com/38377415](http://vimeo.com/38377415)


## Riemann Output Configuration Options [plugins-outputs-riemann-options]

This plugin supports the following configuration options plus the [Common options](#plugins-outputs-riemann-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`debug`](#plugins-outputs-riemann-debug) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`host`](#plugins-outputs-riemann-host) | [string](/reference/configuration-file-structure.md#string) | No |
| [`map_fields`](#plugins-outputs-riemann-map_fields) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`port`](#plugins-outputs-riemann-port) | [number](/reference/configuration-file-structure.md#number) | No |
| [`protocol`](#plugins-outputs-riemann-protocol) | [string](/reference/configuration-file-structure.md#string), one of `["tcp", "udp"]` | No |
| [`riemann_event`](#plugins-outputs-riemann-riemann_event) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`sender`](#plugins-outputs-riemann-sender) | [string](/reference/configuration-file-structure.md#string) | No |

Also see [Common options](#plugins-outputs-riemann-common-options) for a list of options supported by all output plugins.

 

### `debug` [plugins-outputs-riemann-debug]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Enable debugging output?


### `host` [plugins-outputs-riemann-host]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"localhost"`

The address of the Riemann server.


### `map_fields` [plugins-outputs-riemann-map_fields]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

If set to true automatically map all logstash defined fields to riemann event fields. All nested logstash fields will be mapped to riemann fields containing all parent keys separated by dots and the deepest value.

As an example, the logstash event:

```ruby
   {
     "@timestamp":"2013-12-10T14:36:26.151+0000",
     "@version": 1,
     "message":"log message",
     "host": "host.domain.com",
     "nested_field": {
                       "key": "value"
                     }
   }
```

Is mapped to this riemann event:

```ruby
  {
    :time 1386686186,
    :host host.domain.com,
    :message log message,
    :nested_field.key value
  }
```

It can be used in conjunction with or independent of the riemann_event option. When used with the riemann_event any duplicate keys receive their value from riemann_event instead of the logstash event itself.


### `port` [plugins-outputs-riemann-port]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `5555`

The port to connect to on your Riemann server.


### `protocol` [plugins-outputs-riemann-protocol]

* Value can be any of: `tcp`, `udp`
* Default value is `"tcp"`

The protocol to use UDP is non-blocking TCP is blocking

Logstash’s default output behaviour is to never lose events As such, we use tcp as default here


### `riemann_event` [plugins-outputs-riemann-riemann_event]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* There is no default value for this setting.

A Hash to set Riemann event fields ([http://riemann.io/concepts.html](http://riemann.io/concepts.md)).

The following event fields are supported: `description`, `state`, `metric`, `ttl`, `service`

Tags found on the Logstash event will automatically be added to the Riemann event.

Any other field set here will be passed to Riemann as an event attribute.

Example:

```ruby
    riemann {
        riemann_event => {
            "metric"  => "%{metric}"
            "service" => "%{service}"
        }
    }
```

`metric` and `ttl` values will be coerced to a floating point value. Values which cannot be coerced will zero (0.0).

`description`, by default, will be set to the event message but can be overridden here.


### `sender` [plugins-outputs-riemann-sender]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `%{{host}}`

The name of the sender. This sets the `host` value in the Riemann event



## Common options [plugins-outputs-riemann-common-options]

These configuration options are supported by all output plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`codec`](#plugins-outputs-riemann-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-outputs-riemann-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-outputs-riemann-id) | [string](/reference/configuration-file-structure.md#string) | No |

### `codec` [plugins-outputs-riemann-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for output data. Output codecs are a convenient method for encoding your data before it leaves the output without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-outputs-riemann-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance. By default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-outputs-riemann-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type. For example, if you have 2 riemann outputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
output {
  riemann {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::




