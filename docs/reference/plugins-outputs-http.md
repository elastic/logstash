---
navigation_title: "http"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-outputs-http.html
---

# Http output plugin [plugins-outputs-http]


* Plugin version: v6.0.0
* Released on: 2024-11-21
* [Changelog](https://github.com/logstash-plugins/logstash-output-http/blob/v6.0.0/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://docs/reference/output-http-index.md).

## Getting help [_getting_help_85]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-output-http). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_85]

This output lets you send events to a generic HTTP(S) endpoint.

This output will execute up to *pool_max* requests in parallel for performance. Consider this when tuning this plugin for performance.

Additionally, note that when parallel execution is used strict ordering of events is not guaranteed!

Beware, this gem does not yet support codecs. Please use the *format* option for now.


## Retry policy [plugins-outputs-http-retry_policy]

This output has two levels of retry: library and plugin.

### Library retry [plugins-outputs-http-library_retry]

The library retry applies to IO related failures. Non retriable errors include SSL related problems, unresolvable hosts, connection issues, and OS/JVM level interruptions happening during a request.

The options for library retry are:

* [`automatic_retries`](#plugins-outputs-http-automatic_retries). Controls the number of times the plugin should retry after failures at the library level.
* [`retry_non_idempotent`](#plugins-outputs-http-retry_non_idempotent). When set to `false`, GET, HEAD, PUT, DELETE, OPTIONS, and TRACE requests will be retried.


### Plugin retry [plugins-outputs-http-plugin_retry]

The options for plugin level retry are:

* [`retry_failed`](#plugins-outputs-http-retry_failed). When set to `true`, the plugin retries indefinitely for HTTP error response codes defined in the [`retryable_codes`](#plugins-outputs-http-retryable_codes) option (429, 500, 502, 503, 504) and retryable exceptions (socket timeout/ error, DNS resolution failure and client protocol exception).
* [`retryable_codes`](#plugins-outputs-http-retryable_codes). Sets http response codes that trigger a retry.

::::{note}
The `retry_failed` option does not control the library level retry.
::::




## Http Output Configuration Options [plugins-outputs-http-options]

This plugin supports the following configuration options plus the [Common options](#plugins-outputs-http-common-options) described later.

::::{note}
As of version `6.0.0` of this plugin, a number of previously deprecated settings related to SSL have been removed. Please check out [HTTP Output Obsolete Configuration Options](#plugins-outputs-http-obsolete-options) for details.
::::


| Setting | Input type | Required |
| --- | --- | --- |
| [`automatic_retries`](#plugins-outputs-http-automatic_retries) | [number](/reference/configuration-file-structure.md#number) | No |
| [`connect_timeout`](#plugins-outputs-http-connect_timeout) | [number](/reference/configuration-file-structure.md#number) | No |
| [`content_type`](#plugins-outputs-http-content_type) | [string](/reference/configuration-file-structure.md#string) | No |
| [`cookies`](#plugins-outputs-http-cookies) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`follow_redirects`](#plugins-outputs-http-follow_redirects) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`format`](#plugins-outputs-http-format) | [string](/reference/configuration-file-structure.md#string), one of `["json", "json_batch", "form", "message"]` | No |
| [`headers`](#plugins-outputs-http-headers) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`http_compression`](#plugins-outputs-http-http_compression) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`http_method`](#plugins-outputs-http-http_method) | [string](/reference/configuration-file-structure.md#string), one of `["put", "post", "patch", "delete", "get", "head"]` | Yes |
| [`ignorable_codes`](#plugins-outputs-http-ignorable_codes) | [number](/reference/configuration-file-structure.md#number) | No |
| [`keepalive`](#plugins-outputs-http-keepalive) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`mapping`](#plugins-outputs-http-mapping) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`message`](#plugins-outputs-http-message) | [string](/reference/configuration-file-structure.md#string) | No |
| [`pool_max`](#plugins-outputs-http-pool_max) | [number](/reference/configuration-file-structure.md#number) | No |
| [`pool_max_per_route`](#plugins-outputs-http-pool_max_per_route) | [number](/reference/configuration-file-structure.md#number) | No |
| [`proxy`](#plugins-outputs-http-proxy) | <<,>> | No |
| [`request_timeout`](#plugins-outputs-http-request_timeout) | [number](/reference/configuration-file-structure.md#number) | No |
| [`retry_failed`](#plugins-outputs-http-retry_failed) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`retry_non_idempotent`](#plugins-outputs-http-retry_non_idempotent) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`retryable_codes`](#plugins-outputs-http-retryable_codes) | [number](/reference/configuration-file-structure.md#number) | No |
| [`socket_timeout`](#plugins-outputs-http-socket_timeout) | [number](/reference/configuration-file-structure.md#number) | No |
| [`ssl_certificate`](#plugins-outputs-http-ssl_certificate) | [path](/reference/configuration-file-structure.md#path) | No |
| [`ssl_certificate_authorities`](#plugins-outputs-http-ssl_certificate_authorities) | list of [path](/reference/configuration-file-structure.md#path) | No |
| [`ssl_cipher_suites`](#plugins-outputs-http-ssl_cipher_suites) | list of [string](/reference/configuration-file-structure.md#string) | No |
| [`ssl_enabled`](#plugins-outputs-http-ssl_enabled) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`ssl_keystore_password`](#plugins-outputs-http-ssl_keystore_password) | [password](/reference/configuration-file-structure.md#password) | No |
| [`ssl_keystore_path`](#plugins-outputs-http-ssl_keystore_path) | [path](/reference/configuration-file-structure.md#path) | No |
| [`ssl_keystore_type`](#plugins-outputs-http-ssl_keystore_type) | [string](/reference/configuration-file-structure.md#string) | No |
| [`ssl_supported_protocols`](#plugins-outputs-http-ssl_supported_protocols) | [string](/reference/configuration-file-structure.md#string) | No |
| [`ssl_truststore_password`](#plugins-outputs-http-ssl_truststore_password) | [password](/reference/configuration-file-structure.md#password) | No |
| [`ssl_truststore_path`](#plugins-outputs-http-ssl_truststore_path) | [path](/reference/configuration-file-structure.md#path) | No |
| [`ssl_truststore_type`](#plugins-outputs-http-ssl_truststore_type) | [string](/reference/configuration-file-structure.md#string) | No |
| [`ssl_verification_mode`](#plugins-outputs-http-ssl_verification_mode) | [string](/reference/configuration-file-structure.md#string), one of `["full", "none"]` | No |
| [`url`](#plugins-outputs-http-url) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`validate_after_inactivity`](#plugins-outputs-http-validate_after_inactivity) | [number](/reference/configuration-file-structure.md#number) | No |

Also see [Common options](#plugins-outputs-http-common-options) for a list of options supported by all output plugins.

 

### `automatic_retries` [plugins-outputs-http-automatic_retries]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `1`

How many times should the client retry a failing URL. We recommend setting this option to a value other than zero if the [`keepalive` option](#plugins-outputs-http-keepalive) is enabled. Some servers incorrectly end keepalives early, requiring a retry. See [Retry Policy](#plugins-outputs-http-retry_policy) for more information.


### `connect_timeout` [plugins-outputs-http-connect_timeout]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `10`

Timeout (in seconds) to wait for a connection to be established. Default is `10s`


### `content_type` [plugins-outputs-http-content_type]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Content type

If not specified, this defaults to the following:

* if format is "json", "application/json"
* if format is "json_batch", "application/json". Each Logstash batch of events will be concatenated into a single array and sent in one request.
* if format is "form", "application/x-www-form-urlencoded"


### `cookies` [plugins-outputs-http-cookies]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Enable cookie support. With this enabled the client will persist cookies across requests as a normal web browser would. Enabled by default


### `follow_redirects` [plugins-outputs-http-follow_redirects]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Should redirects be followed? Defaults to `true`


### `format` [plugins-outputs-http-format]

* Value can be any of: `json`, `json_batch`, `form`, `message`
* Default value is `"json"`

Set the format of the http body.

If json_batch, each batch of events received by this output will be placed into a single JSON array and sent in one request. This is particularly useful for high throughput scenarios such as sending data between Logstash instaces.

If form, then the body will be the mapping (or whole event) converted into a query parameter string, e.g. `foo=bar&baz=fizz...`

If message, then the body will be the result of formatting the event according to message

Otherwise, the event is sent as json.


### `headers` [plugins-outputs-http-headers]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* There is no default value for this setting.

Custom headers to use format is `headers => ["X-My-Header", "%{{host}}"]`


### `http_compression` [plugins-outputs-http-http_compression]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Enable request compression support. With this enabled the plugin will compress http requests using gzip.


### `http_method` [plugins-outputs-http-http_method]

* This is a required setting.
* Value can be any of: `put`, `post`, `patch`, `delete`, `get`, `head`
* There is no default value for this setting.

The HTTP Verb. One of "put", "post", "patch", "delete", "get", "head"


### `ignorable_codes` [plugins-outputs-http-ignorable_codes]

* Value type is [number](/reference/configuration-file-structure.md#number)
* There is no default value for this setting.

If you would like to consider some non-2xx codes to be successes enumerate them here. Responses returning these codes will be considered successes


### `keepalive` [plugins-outputs-http-keepalive]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Turn this on to enable HTTP keepalive support. We highly recommend setting `automatic_retries` to at least one with this to fix interactions with broken keepalive implementations.


### `mapping` [plugins-outputs-http-mapping]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* There is no default value for this setting.

This lets you choose the structure and parts of the event that are sent.

For example:

```ruby
   mapping => {"foo" => "%{host}"
              "bar" => "%{type}"}
```


### `message` [plugins-outputs-http-message]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.


### `pool_max` [plugins-outputs-http-pool_max]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `50`

Max number of concurrent connections. Defaults to `50`


### `pool_max_per_route` [plugins-outputs-http-pool_max_per_route]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `25`

Max number of concurrent connections to a single host. Defaults to `25`


### `proxy` [plugins-outputs-http-proxy]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

If you’d like to use an HTTP proxy . This supports multiple configuration syntaxes:

1. Proxy host in form: `http://proxy.org:1234`
2. Proxy host in form: `{host => "proxy.org", port => 80, scheme => 'http', user => 'username@host', password => 'password'}`
3. Proxy host in form: `{url =>  'http://proxy.org:1234', user => 'username@host', password => 'password'}`


### `request_timeout` [plugins-outputs-http-request_timeout]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `60`

This module makes it easy to add a very fully configured HTTP client to logstash based on [Manticore](https://github.com/cheald/manticore). For an example of its usage see [https://github.com/logstash-plugins/logstash-input-http_poller](https://github.com/logstash-plugins/logstash-input-http_poller) Timeout (in seconds) for the entire request


### `retry_failed` [plugins-outputs-http-retry_failed]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Note that this option controls plugin-level retries only. It has no affect on library-level retries.

Set this option to `false` if you want to disable infinite retries for HTTP error response codes defined in the [`retryable_codes`](#plugins-outputs-http-retryable_codes) or retryable exceptions (Timeout, SocketException, ClientProtocolException, ResolutionFailure and SocketTimeout). See [Retry policy](#plugins-outputs-http-retry_policy) for more information.


### `retry_non_idempotent` [plugins-outputs-http-retry_non_idempotent]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

When this option is set to `false` and `automatic_retries` is enabled, GET, HEAD, PUT, DELETE, OPTIONS, and TRACE requests will be retried.

When set to `true` and `automatic_retries` is enabled, this will cause non-idempotent HTTP verbs (such as POST) to be retried. See [Retry Policy](#plugins-outputs-http-retry_policy) for more information.


### `retryable_codes` [plugins-outputs-http-retryable_codes]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `[429, 500, 502, 503, 504]`

If the plugin encounters these response codes, the plugin will retry indefinitely. See [Retry Policy](#plugins-outputs-http-retry_policy) for more information.


### `socket_timeout` [plugins-outputs-http-socket_timeout]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `10`

Timeout (in seconds) to wait for data on the socket. Default is `10s`


### `ssl_certificate` [plugins-outputs-http-ssl_certificate]

* Value type is [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting.

SSL certificate to use to authenticate the client. This certificate should be an OpenSSL-style X.509 certificate file.

::::{note}
This setting can be used only if [`ssl_key`](#plugins-outputs-http-ssl_key) is set.
::::



### `ssl_certificate_authorities` [plugins-outputs-http-ssl_certificate_authorities]

* Value type is a list of [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting

The .cer or .pem CA files to validate the server’s certificate.


### `ssl_cipher_suites` [plugins-outputs-http-ssl_cipher_suites]

* Value type is a list of [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting

The list of cipher suites to use, listed by priorities. Supported cipher suites vary depending on the Java and protocol versions.


### `ssl_enabled` [plugins-outputs-http-ssl_enabled]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Enable SSL/TLS secured communication. It must be `true` for other `ssl_` options to take effect.


### `ssl_key` [plugins-outputs-http-ssl_key]

* Value type is [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting.

OpenSSL-style RSA private key that corresponds to the [`ssl_certificate`](#plugins-outputs-http-ssl_certificate).

::::{note}
This setting can be used only if [`ssl_certificate`](#plugins-outputs-http-ssl_certificate) is set.
::::



### `ssl_keystore_password` [plugins-outputs-http-ssl_keystore_password]

* Value type is [password](/reference/configuration-file-structure.md#password)
* There is no default value for this setting.

Set the keystore password


### `ssl_keystore_path` [plugins-outputs-http-ssl_keystore_path]

* Value type is [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting.

The keystore used to present a certificate to the server. It can be either `.jks` or `.p12`


### `ssl_keystore_type` [plugins-outputs-http-ssl_keystore_type]

* Value can be any of: `jks`, `pkcs12`
* If not provided, the value will be inferred from the keystore filename.

The format of the keystore file. It must be either `jks` or `pkcs12`.


### `ssl_supported_protocols` [plugins-outputs-http-ssl_supported_protocols]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Allowed values are: `'TLSv1.1'`, `'TLSv1.2'`, `'TLSv1.3'`
* Default depends on the JDK being used. With up-to-date Logstash, the default is `['TLSv1.2', 'TLSv1.3']`. `'TLSv1.1'` is not considered secure and is only provided for legacy applications.

List of allowed SSL/TLS versions to use when establishing a connection to the HTTP endpoint.

For Java 8 `'TLSv1.3'` is supported  only since **8u262** (AdoptOpenJDK), but requires that you set the `LS_JAVA_OPTS="-Djdk.tls.client.protocols=TLSv1.3"` system property in Logstash.

::::{note}
If you configure the plugin to use `'TLSv1.1'` on any recent JVM, such as the one packaged with Logstash, the protocol is disabled by default and needs to be enabled manually by changing `jdk.tls.disabledAlgorithms` in the **$JDK_HOME/conf/security/java.security** configuration file. That is, `TLSv1.1` needs to be removed from the list.
::::



### `ssl_truststore_password` [plugins-outputs-http-ssl_truststore_password]

* Value type is [password](/reference/configuration-file-structure.md#password)
* There is no default value for this setting.

Set the truststore password


### `ssl_truststore_path` [plugins-outputs-http-ssl_truststore_path]

* Value type is [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting.

The truststore to validate the server’s certificate. It can be either `.jks` or `.p12`.


### `ssl_truststore_type` [plugins-outputs-http-ssl_truststore_type]

* Value can be any of: `jks`, `pkcs12`
* If not provided, the value will be inferred from the truststore filename.

The format of the truststore file. It must be either `jks` or `pkcs12`.


### `ssl_verification_mode` [plugins-outputs-http-ssl_verification_mode]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Supported values are: `full`, `none`
* Default value is `full`

Controls the verification of server certificates. The `full` option verifies that the provided certificate is signed by a trusted authority (CA) and also that the server’s hostname (or IP address) matches the names identified within the certificate.

The `none` setting performs no verification of the server’s certificate. This mode disables many of the security benefits of SSL/TLS and should only be used after cautious consideration. It is primarily intended as a temporary diagnostic mechanism when attempting to resolve TLS errors. Using `none`  in production environments is strongly discouraged.


### `url` [plugins-outputs-http-url]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

URL to use


### `validate_after_inactivity` [plugins-outputs-http-validate_after_inactivity]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `200`

How long to wait before checking if the connection is stale before executing a request on a connection using keepalive. You may want to set this lower, possibly to 0 if you get connection errors regularly Quoting the Apache commons docs (this client is based Apache Commmons): *Defines period of inactivity in milliseconds after which persistent connections must be re-validated prior to being leased to the consumer. Non-positive value passed to this method disables connection validation. This check helps detect connections that have become stale (half-closed) while kept inactive in the pool.* See [these docs for more info](https://hc.apache.org/httpcomponents-client-ga/httpclient/apidocs/org/apache/http/impl/conn/PoolingHttpClientConnectionManager.md#setValidateAfterInactivity(int))



## HTTP Output Obsolete Configuration Options [plugins-outputs-http-obsolete-options]

::::{warning}
As of version `6.0.0` of this plugin, some configuration options have been replaced. The plugin will fail to start if it contains any of these obsolete options.
::::


| Setting | Replaced by |
| --- | --- |
| cacert | [`ssl_certificate_authorities`](#plugins-outputs-http-ssl_certificate_authorities) |
| client_cert | [`ssl_certificate`](#plugins-outputs-http-ssl_certificate) |
| client_key | [`ssl_key`](#plugins-outputs-http-ssl_key) |
| keystore | [`ssl_keystore_path`](#plugins-outputs-http-ssl_keystore_path) |
| keystore_password | [`ssl_keystore_password`](#plugins-outputs-http-ssl_keystore_password) |
| keystore_type | [`ssl_keystore_password`](#plugins-outputs-http-ssl_keystore_password) |
| truststore | [`ssl_truststore_path`](#plugins-outputs-http-ssl_truststore_path) |
| truststore_password | [`ssl_truststore_password`](#plugins-outputs-http-ssl_truststore_password) |
| truststore_type | [`ssl_truststore_type`](#plugins-outputs-http-ssl_truststore_type) |


## Common options [plugins-outputs-http-common-options]

These configuration options are supported by all output plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`codec`](#plugins-outputs-http-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-outputs-http-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-outputs-http-id) | [string](/reference/configuration-file-structure.md#string) | No |

### `codec` [plugins-outputs-http-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for output data. Output codecs are a convenient method for encoding your data before it leaves the output without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-outputs-http-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance. By default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-outputs-http-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type. For example, if you have 2 http outputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
output {
  http {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::
