---
navigation_title: "timber"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-outputs-timber.html
---

# Timber output plugin [plugins-outputs-timber]


* Plugin version: v1.0.3
* Released on: 2017-09-02
* [Changelog](https://github.com/logstash-plugins/logstash-output-timber/blob/v1.0.3/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://docs/reference/output-timber-index.md).

## Installation [_installation_50]

For plugins not bundled by default, it is easy to install by running `bin/logstash-plugin install logstash-output-timber`. See [Working with plugins](/reference/working-with-plugins.md) for more details.


## Getting help [_getting_help_117]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-output-timber). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_117]

This output sends structured events to the [Timber.io logging service](https://timber.io). Timber is a cloud-based logging service designed for developers, providing easy features out of the box that make you more productive. [Tail users](https://timber.io/docs/app/console/tail-a-user), [trace requests](https://timber.io/docs/app/console/trace-http-requests), [inspect HTTP parameters](https://timber.io/docs/app/console/inspect-http-requests), and [search](https://timber.io/docs/app/console/searching) on rich structured data without sacrificing readability.

Internally, it’s a highly efficient HTTP transport that uses batching and retries for fast and reliable delivery.

This output will execute up to *pool_max* requests in parallel for performance. Consider this when tuning this plugin for performance. The default of 50 should be sufficient for most setups.

Additionally, note that when parallel execution is used strict ordering of events is not guaranteed!


## Timber Output Configuration Options [plugins-outputs-timber-options]

This plugin supports the following configuration options plus the [Common options](#plugins-outputs-timber-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`api_key`](#plugins-outputs-timber-api_key) | Your Timber.io API key | No |
| [`cacert`](#plugins-outputs-timber-cacert) | a valid filesystem path | No |
| [`client_cert`](#plugins-outputs-timber-client_cert) | a valid filesystem path | No |
| [`client_key`](#plugins-outputs-timber-client_key) | a valid filesystem path | No |
| [`connect_timeout`](#plugins-outputs-timber-connect_timeout) | [number](/reference/configuration-file-structure.md#number) | No |
| [`keystore`](#plugins-outputs-timber-keystore) | a valid filesystem path | No |
| [`keystore_password`](#plugins-outputs-timber-keystore_password) | [password](/reference/configuration-file-structure.md#password) | No |
| [`keystore_type`](#plugins-outputs-timber-keystore_type) | [string](/reference/configuration-file-structure.md#string) | No |
| [`pool_max`](#plugins-outputs-timber-pool_max) | [number](/reference/configuration-file-structure.md#number) | No |
| [`proxy`](#plugins-outputs-timber-proxy) | <<,>> | No |
| [`request_timeout`](#plugins-outputs-timber-request_timeout) | [number](/reference/configuration-file-structure.md#number) | No |
| [`socket_timeout`](#plugins-outputs-timber-socket_timeout) | [number](/reference/configuration-file-structure.md#number) | No |
| [`truststore`](#plugins-outputs-timber-truststore) | a valid filesystem path | No |
| [`truststore_password`](#plugins-outputs-timber-truststore_password) | [password](/reference/configuration-file-structure.md#password) | No |
| [`truststore_type`](#plugins-outputs-timber-truststore_type) | [string](/reference/configuration-file-structure.md#string) | No |

Also see [Common options](#plugins-outputs-timber-common-options) for a list of options supported by all output plugins.

 

### `api_key` [plugins-outputs-timber-api_key]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Your Timber.io API key. You can obtain your API by creating an app in the [Timber console](https://app.timber.io).


### `cacert` [plugins-outputs-timber-cacert]

* Value type is [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting.

If you need to use a custom X.509 CA (.pem certs) specify the path to that here.


### `client_cert` [plugins-outputs-timber-client_cert]

* Value type is [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting.

If you’d like to use a client certificate (note, most people don’t want this) set the path to the x509 cert here


### `client_key` [plugins-outputs-timber-client_key]

* Value type is [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting.

If you’re using a client certificate specify the path to the encryption key here


### `connect_timeout` [plugins-outputs-timber-connect_timeout]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `10`

Timeout (in seconds) to wait for a connection to be established. Default is `10s`


### `keystore` [plugins-outputs-timber-keystore]

* Value type is [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting.

If you need to use a custom keystore (`.jks`) specify that here. This does not work with .pem keys!


### `keystore_password` [plugins-outputs-timber-keystore_password]

* Value type is [password](/reference/configuration-file-structure.md#password)
* There is no default value for this setting.

Specify the keystore password here. Note, most .jks files created with keytool require a password!


### `keystore_type` [plugins-outputs-timber-keystore_type]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"JKS"`

Specify the keystore type here. One of `JKS` or `PKCS12`. Default is `JKS`


### `pool_max` [plugins-outputs-timber-pool_max]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `50`

Max number of concurrent connections. Defaults to `50`


### `proxy` [plugins-outputs-timber-proxy]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

If you’d like to use an HTTP proxy . This supports multiple configuration syntaxes:

1. Proxy host in form: `http://proxy.org:1234`
2. Proxy host in form: `{host => "proxy.org", port => 80, scheme => 'http', user => 'username@host', password => 'password'}`
3. Proxy host in form: `{url =>  'http://proxy.org:1234', user => 'username@host', password => 'password'}`


### `request_timeout` [plugins-outputs-timber-request_timeout]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `60`

This module makes it easy to add a very fully configured HTTP client to logstash based on [Manticore](https://github.com/cheald/manticore). For an example of its usage see [https://github.com/logstash-plugins/logstash-input-http_poller](https://github.com/logstash-plugins/logstash-input-http_poller) Timeout (in seconds) for the entire request


### `socket_timeout` [plugins-outputs-timber-socket_timeout]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `10`

Timeout (in seconds) to wait for data on the socket. Default is `10s`


### `ssl_certificate_validation` [plugins-outputs-timber-ssl_certificate_validation]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Set this to false to disable SSL/TLS certificate validation Note: setting this to false is generally considered insecure!


### `truststore` [plugins-outputs-timber-truststore]

* Value type is [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting.

If you need to use a custom truststore (`.jks`) specify that here. This does not work with .pem certs!


### `truststore_password` [plugins-outputs-timber-truststore_password]

* Value type is [password](/reference/configuration-file-structure.md#password)
* There is no default value for this setting.

Specify the truststore password here. Note, most .jks files created with keytool require a password!


### `truststore_type` [plugins-outputs-timber-truststore_type]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"JKS"`

Specify the truststore type here. One of `JKS` or `PKCS12`. Default is `JKS`



## Common options [plugins-outputs-timber-common-options]

These configuration options are supported by all output plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`codec`](#plugins-outputs-timber-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-outputs-timber-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-outputs-timber-id) | [string](/reference/configuration-file-structure.md#string) | No |

### `codec` [plugins-outputs-timber-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for output data. Output codecs are a convenient method for encoding your data before it leaves the output without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-outputs-timber-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance. By default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-outputs-timber-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type. For example, if you have 2 timber outputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
output {
  timber {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::




