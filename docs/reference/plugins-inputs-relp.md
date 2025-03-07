---
navigation_title: "relp"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-inputs-relp.html
---

# Relp input plugin [plugins-inputs-relp]


* Plugin version: v3.0.4
* Released on: 2018-04-06
* [Changelog](https://github.com/logstash-plugins/logstash-input-relp/blob/v3.0.4/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://reference/input-relp-index.md).

## Installation [_installation_11]

For plugins not bundled by default, it is easy to install by running `bin/logstash-plugin install logstash-input-relp`. See [Working with plugins](/reference/working-with-plugins.md) for more details.


## Getting help [_getting_help_45]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-input-relp). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_45]

Read RELP events over a TCP socket.

For more information about RELP, see [http://www.rsyslog.com/doc/imrelp.html](http://www.rsyslog.com/doc/imrelp.html)

This protocol implements application-level acknowledgements to help protect against message loss.

Message acks only function as far as messages being put into the queue for filters; anything lost after that point will not be retransmitted


## Relp Input Configuration Options [plugins-inputs-relp-options]

This plugin supports the following configuration options plus the [Common options](#plugins-inputs-relp-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`host`](#plugins-inputs-relp-host) | [string](/reference/configuration-file-structure.md#string) | No |
| [`port`](#plugins-inputs-relp-port) | [number](/reference/configuration-file-structure.md#number) | Yes |
| [`ssl_cacert`](#plugins-inputs-relp-ssl_cacert) | a valid filesystem path | No |
| [`ssl_cert`](#plugins-inputs-relp-ssl_cert) | a valid filesystem path | No |
| [`ssl_enable`](#plugins-inputs-relp-ssl_enable) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`ssl_key`](#plugins-inputs-relp-ssl_key) | a valid filesystem path | No |
| [`ssl_key_passphrase`](#plugins-inputs-relp-ssl_key_passphrase) | [password](/reference/configuration-file-structure.md#password) | No |
| [`ssl_verify`](#plugins-inputs-relp-ssl_verify) | [boolean](/reference/configuration-file-structure.md#boolean) | No |

Also see [Common options](#plugins-inputs-relp-common-options) for a list of options supported by all input plugins.

 

### `host` [plugins-inputs-relp-host]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"0.0.0.0"`

The address to listen on.


### `port` [plugins-inputs-relp-port]

* This is a required setting.
* Value type is [number](/reference/configuration-file-structure.md#number)
* There is no default value for this setting.

The port to listen on.


### `ssl_cacert` [plugins-inputs-relp-ssl_cacert]

* Value type is [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting.

The SSL CA certificate, chainfile or CA path. The system CA path is automatically included.


### `ssl_cert` [plugins-inputs-relp-ssl_cert]

* Value type is [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting.

SSL certificate path


### `ssl_enable` [plugins-inputs-relp-ssl_enable]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Enable SSL (must be set for other `ssl_` options to take effect).


### `ssl_key` [plugins-inputs-relp-ssl_key]

* Value type is [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting.

SSL key path


### `ssl_key_passphrase` [plugins-inputs-relp-ssl_key_passphrase]

* Value type is [password](/reference/configuration-file-structure.md#password)
* Default value is `nil`

SSL key passphrase


### `ssl_verify` [plugins-inputs-relp-ssl_verify]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Verify the identity of the other end of the SSL connection against the CA. For input, sets the field `sslsubject` to that of the client certificate.



## Common options [plugins-inputs-relp-common-options]

These configuration options are supported by all input plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`add_field`](#plugins-inputs-relp-add_field) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`codec`](#plugins-inputs-relp-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-inputs-relp-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-inputs-relp-id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`tags`](#plugins-inputs-relp-tags) | [array](/reference/configuration-file-structure.md#array) | No |
| [`type`](#plugins-inputs-relp-type) | [string](/reference/configuration-file-structure.md#string) | No |

### `add_field` [plugins-inputs-relp-add_field]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

Add a field to an event


### `codec` [plugins-inputs-relp-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for input data. Input codecs are a convenient method for decoding your data before it enters the input, without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-inputs-relp-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance by default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-inputs-relp-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type, for example, if you have 2 relp inputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
input {
  relp {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::



### `tags` [plugins-inputs-relp-tags]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

Add any number of arbitrary tags to your event.

This can help with processing later.


### `type` [plugins-inputs-relp-type]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a `type` field to all events handled by this input.

Types are used mainly for filter activation.

The type is stored as part of the event itself, so you can also use the type to search for it in Kibana.

If you try to set a type on an event that already has one (for example when you send an event from a shipper to an indexer) then a new input will not override the existing type. A type set at the shipper stays with that event for its life even when sent to another Logstash server.



