---
navigation_title: "tcp"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-outputs-tcp.html
---

# Tcp output plugin [plugins-outputs-tcp]


* Plugin version: v7.0.0
* Released on: 2025-01-10
* [Changelog](https://github.com/logstash-plugins/logstash-output-tcp/blob/v7.0.0/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://reference/output-tcp-index.md).

## Getting help [_getting_help_116]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-output-tcp). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_116]

Write events over a TCP socket.

By default this plugin uses the `json` codec. In order to have each event json separated by a newline, use the `json_lines` codec.

Can either accept connections from clients or connect to a server, depending on `mode`.


## Tcp Output Configuration Options [plugins-outputs-tcp-options]

This plugin supports the following configuration options plus the [Common options](#plugins-outputs-tcp-common-options) described later.

::::{note}
As of version `7.0.0` of this plugin, a number of previously deprecated settings related to SSL have been removed. Please see the [TCP Output Obsolete Configuration Options](#plugins-outputs-tcp-obsolete-options) for more details.
::::


| Setting | Input type | Required |
| --- | --- | --- |
| [`host`](#plugins-outputs-tcp-host) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`mode`](#plugins-outputs-tcp-mode) | [string](/reference/configuration-file-structure.md#string), one of `["server", "client"]` | No |
| [`port`](#plugins-outputs-tcp-port) | [number](/reference/configuration-file-structure.md#number) | Yes |
| [`reconnect_interval`](#plugins-outputs-tcp-reconnect_interval) | [number](/reference/configuration-file-structure.md#number) | No |
| [`ssl_certificate`](#plugins-outputs-tcp-ssl_certificate) | a valid filesystem path | No |
| [`ssl_certificate_authorities`](#plugins-outputs-tcp-ssl_certificate_authorities) | [array](/reference/configuration-file-structure.md#array) | No |
| [`ssl_cipher_suites`](#plugins-outputs-tcp-ssl_cipher_suites) | [string](/reference/configuration-file-structure.md#string) | No |
| [`ssl_client_authentication`](#plugins-outputs-tcp-ssl_client_authentication) | [string](/reference/configuration-file-structure.md#string), one of `["none", "optional", "required"]` | No |
| [`ssl_enabled`](#plugins-outputs-tcp-ssl_enabled) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`ssl_key`](#plugins-outputs-tcp-ssl_key) | a valid filesystem path | No |
| [`ssl_key_passphrase`](#plugins-outputs-tcp-ssl_key_passphrase) | [password](/reference/configuration-file-structure.md#password) | No |
| [`ssl_supported_protocols`](#plugins-outputs-tcp-ssl_supported_protocols) | [string](/reference/configuration-file-structure.md#string) | No |
| [`ssl_verification_mode`](#plugins-outputs-tcp-ssl_verification_mode) | [string](/reference/configuration-file-structure.md#string), one of `["full", "none"]` | No |

Also see [Common options](#plugins-outputs-tcp-common-options) for a list of options supported by all output plugins.

 

### `host` [plugins-outputs-tcp-host]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

When mode is `server`, the address to listen on. When mode is `client`, the address to connect to.


### `mode` [plugins-outputs-tcp-mode]

* Value can be any of: `server`, `client`
* Default value is `"client"`

Mode to operate in. `server` listens for client connections, `client` connects to a server.


### `port` [plugins-outputs-tcp-port]

* This is a required setting.
* Value type is [number](/reference/configuration-file-structure.md#number)
* There is no default value for this setting.

When mode is `server`, the port to listen on. When mode is `client`, the port to connect to.


### `reconnect_interval` [plugins-outputs-tcp-reconnect_interval]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `10`

When connect failed,retry interval in sec.


### `ssl_certificate` [plugins-outputs-tcp-ssl_certificate]

* Value type is [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting.

Path to certificate in PEM format. This certificate will be presented to the other part of the TLS connection.


### `ssl_certificate_authorities` [plugins-outputs-tcp-ssl_certificate_authorities]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

Validate client certificate or certificate chain against these authorities. You can define multiple files. All the certificates will be read and added to the trust store. The system CA path is automatically included.


### `ssl_cipher_suites` [plugins-outputs-tcp-ssl_cipher_suites]

* Value type is a list of [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting

The list of cipher suites to use, listed by priorities. Supported cipher suites vary depending on the Java and protocol versions.


### `ssl_client_authentication` [plugins-outputs-tcp-ssl_client_authentication]

* Value can be any of: `none`, `optional`, `required`
* Default value is `none`

Controls the server’s behavior in regard to requesting a certificate from client connections: `none` disables the client authentication. `required` forces a client to present a certificate, while `optional` requests a client certificate but the client is not required to present one.

When mutual TLS is enabled (`optional` or `required`), the certificate presented by the client must be signed by trusted [`ssl_certificate_authorities`](#plugins-outputs-tcp-ssl_certificate_authorities) (CAs). Please note that the server does not validate the client certificate CN (Common Name) or SAN (Subject Alternative Name).

::::{note}
This setting can be used only if [`mode`](#plugins-outputs-tcp-mode) is `server` and [`ssl_certificate_authorities`](#plugins-outputs-tcp-ssl_certificate_authorities) is set.
::::



### `ssl_enabled` [plugins-outputs-tcp-ssl_enabled]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Enable SSL (must be set for other `ssl_` options to take effect).


### `ssl_key` [plugins-outputs-tcp-ssl_key]

* Value type is [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting.

SSL key path


### `ssl_key_passphrase` [plugins-outputs-tcp-ssl_key_passphrase]

* Value type is [password](/reference/configuration-file-structure.md#password)
* Default value is `nil`

SSL key passphrase


### `ssl_supported_protocols` [plugins-outputs-tcp-ssl_supported_protocols]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Allowed values are: `'TLSv1.1'`, `'TLSv1.2'`, `'TLSv1.3'`
* Default depends on the JDK being used. With up-to-date Logstash, the default is `['TLSv1.2', 'TLSv1.3']`. `'TLSv1.1'` is not considered secure and is only provided for legacy applications.

List of allowed SSL/TLS versions to use when establishing a secure connection.

::::{note}
If you configure the plugin to use `'TLSv1.1'` on any recent JVM, such as the one packaged with Logstash, the protocol is disabled by default and needs to be enabled manually by changing `jdk.tls.disabledAlgorithms` in the **$JDK_HOME/conf/security/java.security** configuration file. That is, `TLSv1.1` needs to be removed from the list.
::::



### `ssl_verification_mode` [plugins-outputs-tcp-ssl_verification_mode]

* Value can be any of: `full`, `none`
* Default value is `full`

Defines how to verify the certificates presented by another part in the TLS connection:

`full` validates that the server certificate has an issue date that’s within the not_before and not_after dates; chains to a trusted Certificate Authority (CA), and has a hostname or IP address that matches the names within the certificate.

`none` performs no certificate validation.

::::{note}
This setting can be used only if [`mode`](#plugins-outputs-tcp-mode) is `client`.
::::




## TCP Output Obsolete Configuration Options [plugins-outputs-tcp-obsolete-options]

::::{warning}
As of version `6.0.0` of this plugin, some configuration options have been replaced. The plugin will fail to start if it contains any of these obsolete options.
::::


| Setting | Replaced by |
| --- | --- |
| ssl_cacert | [`ssl_certificate_authorities`](#plugins-outputs-tcp-ssl_certificate_authorities) |
| ssl_cert | [`ssl_certificate`](#plugins-outputs-tcp-ssl_certificate) |
| ssl_enable | [`ssl_enabled`](#plugins-outputs-tcp-ssl_enabled) |
| ssl_verify | [`ssl_client_authentication`](#plugins-outputs-tcp-ssl_client_authentication) in `server` mode and [`ssl_verification_mode`](#plugins-outputs-tcp-ssl_verification_mode) in `client` mode |


## Common options [plugins-outputs-tcp-common-options]

These configuration options are supported by all output plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`codec`](#plugins-outputs-tcp-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-outputs-tcp-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-outputs-tcp-id) | [string](/reference/configuration-file-structure.md#string) | No |

### `codec` [plugins-outputs-tcp-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"json"`

The codec used for output data. Output codecs are a convenient method for encoding your data before it leaves the output without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-outputs-tcp-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance. By default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-outputs-tcp-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type. For example, if you have 2 tcp outputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
output {
  tcp {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::




