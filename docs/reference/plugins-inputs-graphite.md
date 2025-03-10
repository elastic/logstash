---
navigation_title: "graphite"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-inputs-graphite.html
---

# Graphite input plugin [plugins-inputs-graphite]


* Plugin version: v3.0.6
* Released on: 2018-04-06
* [Changelog](https://github.com/logstash-plugins/logstash-input-graphite/blob/v3.0.6/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://reference/input-graphite-index.md).

## Getting help [_getting_help_24]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-input-graphite). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_24]

Receive graphite metrics. This plugin understands the text-based graphite carbon protocol. Both `N` and `specific-timestamp` forms are supported, example:

```ruby
    mysql.slow_query.count 204 N
    haproxy.live_backends 7 1364608909
```

`N` means `now` for a timestamp. This plugin also supports having the time specified in the metric payload:

For every metric received from a client, a single event will be emitted with the metric name as the field (like `mysql.slow_query.count`) and the metric value as the field’s value.


## Graphite Input Configuration Options [plugins-inputs-graphite-options]

This plugin supports the following configuration options plus the [Common options](#plugins-inputs-graphite-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`host`](#plugins-inputs-graphite-host) | [string](/reference/configuration-file-structure.md#string) | No |
| [`mode`](#plugins-inputs-graphite-mode) | [string](/reference/configuration-file-structure.md#string), one of `["server", "client"]` | No |
| [`port`](#plugins-inputs-graphite-port) | [number](/reference/configuration-file-structure.md#number) | Yes |
| [`proxy_protocol`](#plugins-inputs-graphite-proxy_protocol) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`ssl_cert`](#plugins-inputs-graphite-ssl_cert) | a valid filesystem path | No |
| [`ssl_enable`](#plugins-inputs-graphite-ssl_enable) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`ssl_extra_chain_certs`](#plugins-inputs-graphite-ssl_extra_chain_certs) | [array](/reference/configuration-file-structure.md#array) | No |
| [`ssl_key`](#plugins-inputs-graphite-ssl_key) | a valid filesystem path | No |
| [`ssl_key_passphrase`](#plugins-inputs-graphite-ssl_key_passphrase) | [password](/reference/configuration-file-structure.md#password) | No |
| [`ssl_verify`](#plugins-inputs-graphite-ssl_verify) | [boolean](/reference/configuration-file-structure.md#boolean) | No |

Also see [Common options](#plugins-inputs-graphite-common-options) for a list of options supported by all input plugins.

 

### `data_timeout`  (DEPRECATED) [plugins-inputs-graphite-data_timeout]

* DEPRECATED WARNING: This configuration item is deprecated and may not be available in future versions.
* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `-1`


### `host` [plugins-inputs-graphite-host]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"0.0.0.0"`

Read events over a TCP socket.

Like stdin and file inputs, each event is assumed to be one line of text.

Can either accept connections from clients or connect to a server, depending on `mode`. When mode is `server`, the address to listen on. When mode is `client`, the address to connect to.


### `mode` [plugins-inputs-graphite-mode]

* Value can be any of: `server`, `client`
* Default value is `"server"`

Mode to operate in. `server` listens for client connections, `client` connects to a server.


### `port` [plugins-inputs-graphite-port]

* This is a required setting.
* Value type is [number](/reference/configuration-file-structure.md#number)
* There is no default value for this setting.

When mode is `server`, the port to listen on. When mode is `client`, the port to connect to.


### `proxy_protocol` [plugins-inputs-graphite-proxy_protocol]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Proxy protocol support, only v1 is supported at this time [http://www.haproxy.org/download/1.5/doc/proxy-protocol.txt](http://www.haproxy.org/download/1.5/doc/proxy-protocol.txt)


### `ssl_cacert`  (DEPRECATED) [plugins-inputs-graphite-ssl_cacert]

* DEPRECATED WARNING: This configuration item is deprecated and may not be available in future versions.
* Value type is [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting.

The SSL CA certificate, chainfile or CA path. The system CA path is automatically included.


### `ssl_cert` [plugins-inputs-graphite-ssl_cert]

* Value type is [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting.

SSL certificate path


### `ssl_enable` [plugins-inputs-graphite-ssl_enable]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Enable SSL (must be set for other `ssl_` options to take effect).


### `ssl_extra_chain_certs` [plugins-inputs-graphite-ssl_extra_chain_certs]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

An Array of extra X509 certificates to be added to the certificate chain. Useful when the CA chain is not necessary in the system store.


### `ssl_key` [plugins-inputs-graphite-ssl_key]

* Value type is [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting.

SSL key path


### `ssl_key_passphrase` [plugins-inputs-graphite-ssl_key_passphrase]

* Value type is [password](/reference/configuration-file-structure.md#password)
* Default value is `nil`

SSL key passphrase


### `ssl_verify` [plugins-inputs-graphite-ssl_verify]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Verify the identity of the other end of the SSL connection against the CA. For input, sets the field `sslsubject` to that of the client certificate.



## Common options [plugins-inputs-graphite-common-options]

These configuration options are supported by all input plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`add_field`](#plugins-inputs-graphite-add_field) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`codec`](#plugins-inputs-graphite-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-inputs-graphite-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-inputs-graphite-id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`tags`](#plugins-inputs-graphite-tags) | [array](/reference/configuration-file-structure.md#array) | No |
| [`type`](#plugins-inputs-graphite-type) | [string](/reference/configuration-file-structure.md#string) | No |

### `add_field` [plugins-inputs-graphite-add_field]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

Add a field to an event


### `codec` [plugins-inputs-graphite-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for input data. Input codecs are a convenient method for decoding your data before it enters the input, without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-inputs-graphite-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance by default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-inputs-graphite-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type, for example, if you have 2 graphite inputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
input {
  graphite {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::



### `tags` [plugins-inputs-graphite-tags]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

Add any number of arbitrary tags to your event.

This can help with processing later.


### `type` [plugins-inputs-graphite-type]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a `type` field to all events handled by this input.

Types are used mainly for filter activation.

The type is stored as part of the event itself, so you can also use the type to search for it in Kibana.

If you try to set a type on an event that already has one (for example when you send an event from a shipper to an indexer) then a new input will not override the existing type. A type set at the shipper stays with that event for its life even when sent to another Logstash server.



