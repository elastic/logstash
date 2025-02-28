---
navigation_title: "http"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-filters-http.html
---

# HTTP filter plugin [plugins-filters-http]


* Plugin version: v2.0.0
* Released on: 2024-12-18
* [Changelog](https://github.com/logstash-plugins/logstash-filter-http/blob/v2.0.0/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://reference/filter-http-index.md).

## Getting help [_getting_help_144]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-filter-http). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_143]

The HTTP filter provides integration with external web services/REST APIs.


## Compatibility with the Elastic Common Schema (ECS) [plugins-filters-http-ecs]

The plugin includes sensible defaults that change based on [ECS compatibility mode](#plugins-filters-http-ecs_compatibility). When targeting an ECS version, headers are set as `@metadata` and the `target_body` is a required option. See [`target_body`](#plugins-filters-http-target_body), and [`target_headers`](#plugins-filters-http-target_headers).


## HTTP Filter Configuration Options [plugins-filters-http-options]

This plugin supports the following configuration options plus the [Common options](#plugins-filters-http-common-options) described later.

::::{note}
As of version `2.0.0` of this plugin, a number of previously deprecated settings related to SSL have been removed. Please check out [HTTP Filter Obsolete Configuration Options](#plugins-filters-http-obsolete-options) for details.
::::


| Setting | Input type | Required |
| --- | --- | --- |
| [`body`](#plugins-filters-http-body) | String, Array or Hash | No |
| [`body_format`](#plugins-filters-http-body_format) | [string](/reference/configuration-file-structure.md#string) | No |
| [`ecs_compatibility`](#plugins-filters-http-ecs_compatibility) | [string](/reference/configuration-file-structure.md#string) | No |
| [`headers`](#plugins-filters-http-headers) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`query`](#plugins-filters-http-query) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`target_body`](#plugins-filters-http-target_body) | [string](/reference/configuration-file-structure.md#string) | No |
| [`target_headers`](#plugins-filters-http-target_headers) | [string](/reference/configuration-file-structure.md#string) | No |
| [`url`](#plugins-filters-http-url) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`verb`](#plugins-filters-http-verb) | [string](/reference/configuration-file-structure.md#string) | No |

There are also multiple configuration options related to the HTTP connectivity:

| Setting | Input type | Required |
| --- | --- | --- |
| [`automatic_retries`](#plugins-filters-http-automatic_retries) | [number](/reference/configuration-file-structure.md#number) | No |
| [`connect_timeout`](#plugins-filters-http-connect_timeout) | [number](/reference/configuration-file-structure.md#number) | No |
| [`cookies`](#plugins-filters-http-cookies) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`follow_redirects`](#plugins-filters-http-follow_redirects) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`keepalive`](#plugins-filters-http-keepalive) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`password`](#plugins-filters-http-password) | [password](/reference/configuration-file-structure.md#password) | No |
| [`pool_max`](#plugins-filters-http-pool_max) | [number](/reference/configuration-file-structure.md#number) | No |
| [`pool_max_per_route`](#plugins-filters-http-pool_max_per_route) | [number](/reference/configuration-file-structure.md#number) | No |
| [`proxy`](#plugins-filters-http-proxy) | [string](/reference/configuration-file-structure.md#string) | No |
| [`request_timeout`](#plugins-filters-http-request_timeout) | [number](/reference/configuration-file-structure.md#number) | No |
| [`retry_non_idempotent`](#plugins-filters-http-retry_non_idempotent) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`socket_timeout`](#plugins-filters-http-socket_timeout) | [number](/reference/configuration-file-structure.md#number) | No |
| [`ssl_certificate`](#plugins-filters-http-ssl_certificate) | [path](/reference/configuration-file-structure.md#path) | No |
| [`ssl_certificate_authorities`](#plugins-filters-http-ssl_certificate_authorities) | list of [path](/reference/configuration-file-structure.md#path) | No |
| [`ssl_cipher_suites`](#plugins-filters-http-ssl_cipher_suites) | list of [string](/reference/configuration-file-structure.md#string) | No |
| [`ssl_enabled`](#plugins-filters-http-ssl_enabled) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`ssl_keystore_password`](#plugins-filters-http-ssl_keystore_password) | [password](/reference/configuration-file-structure.md#password) | No |
| [`ssl_keystore_path`](#plugins-filters-http-ssl_keystore_path) | [path](/reference/configuration-file-structure.md#path) | No |
| [`ssl_keystore_type`](#plugins-filters-http-ssl_keystore_type) | [string](/reference/configuration-file-structure.md#string) | No |
| [`ssl_supported_protocols`](#plugins-filters-http-ssl_supported_protocols) | [string](/reference/configuration-file-structure.md#string) | No |
| [`ssl_truststore_password`](#plugins-filters-http-ssl_truststore_password) | [password](/reference/configuration-file-structure.md#password) | No |
| [`ssl_truststore_path`](#plugins-filters-http-ssl_truststore_path) | [path](/reference/configuration-file-structure.md#path) | No |
| [`ssl_truststore_type`](#plugins-filters-http-ssl_truststore_type) | [string](/reference/configuration-file-structure.md#string) | No |
| [`ssl_verification_mode`](#plugins-filters-http-ssl_verification_mode) | [string](/reference/configuration-file-structure.md#string), one of `["full", "none"]` | No |
| [`user`](#plugins-filters-http-user) | [string](/reference/configuration-file-structure.md#string) | no |
| [`validate_after_inactivity`](#plugins-filters-http-validate_after_inactivity) | [number](/reference/configuration-file-structure.md#number) | No |

Also see [Common options](#plugins-filters-http-common-options) for a list of options supported by all filter plugins.

 

### `body` [plugins-filters-http-body]

* Value type can be a [string](/reference/configuration-file-structure.md#string), [number](/reference/configuration-file-structure.md#number), [array](/reference/configuration-file-structure.md#array) or [hash](/reference/configuration-file-structure.md#hash)
* There is no default value

The body of the HTTP request to be sent.

An example to send `body` as json

```
http {
  body => {
    "key1" => "constant_value"
    "key2" => "%{[field][reference]}"
  }
  body_format => "json"
}
```


### `body_format` [plugins-filters-http-body_format]

* Value type can be either `"json"` or `"text"`
* Default value is `"text"`

If set to `"json"` and the [`body`](#plugins-filters-http-body) is a type of [array](/reference/configuration-file-structure.md#array) or [hash](/reference/configuration-file-structure.md#hash), the body will be serialized as JSON. Otherwise it is sent as is.


### `ecs_compatibility` [plugins-filters-http-ecs_compatibility]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Supported values are:

    * `disabled`: does not use ECS-compatible field names (for example, response headers target `headers` field by default)
    * `v1`, `v8`: avoids field names that might conflict with Elastic Common Schema (for example, headers are added as metadata)

* Default value depends on which version of Logstash is running:

    * When Logstash provides a `pipeline.ecs_compatibility` setting, its value is used as the default
    * Otherwise, the default value is `disabled`.


Controls this plugin’s compatibility with the [Elastic Common Schema (ECS)][Elastic Common Schema (ECS)](ecs://reference/index.md)). The value of this setting affects the *default* value of [`target_body`](#plugins-filters-http-target_body) and [`target_headers`](#plugins-filters-http-target_headers).


### `headers` [plugins-filters-http-headers]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* There is no default value

The HTTP headers to be sent in the request. Both the names of the headers and their values can reference values from event fields.


### `query` [plugins-filters-http-query]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* There is no default value

Define the query string parameters (key-value pairs) to be sent in the HTTP request.


### `target_body` [plugins-filters-http-target_body]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value depends on whether [`ecs_compatibility`](#plugins-filters-http-ecs_compatibility) is enabled:

    * ECS Compatibility disabled: `"[body]"
    * ECS Compatibility enabled: no default value, needs to be specified explicitly


Define the target field for placing the body of the HTTP response.


### `target_headers` [plugins-filters-http-target_headers]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value depends on whether [`ecs_compatibility`](#plugins-filters-http-ecs_compatibility) is enabled:

    * ECS Compatibility disabled: `"[headers]"`
    * ECS Compatibility enabled: `"[@metadata][filter][http][response][headers]"`


Define the target field for placing the headers of the HTTP response.


### `url` [plugins-filters-http-url]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value

The URL to send the request to. The value can be fetched from event fields.


### `verb` [plugins-filters-http-verb]

* Value type can be either `"GET"`, `"HEAD"`, `"PATCH"`, `"DELETE"`, `"POST"`, `"PUT"`
* Default value is `"GET"`

The verb to be used for the HTTP request.



## HTTP Filter Connectivity Options [plugins-filters-http-connectivity-options]

### `automatic_retries` [plugins-filters-http-automatic_retries]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `1`

How many times should the client retry a failing URL. We highly recommend NOT setting this value to zero if keepalive is enabled. Some servers incorrectly end keepalives early requiring a retry! Note: if `retry_non_idempotent` is set only GET, HEAD, PUT, DELETE, OPTIONS, and TRACE requests will be retried.


### `connect_timeout` [plugins-filters-http-connect_timeout]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `10`

Timeout (in seconds) to wait for a connection to be established. Default is `10s`


### `cookies` [plugins-filters-http-cookies]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Enable cookie support. With this enabled the client will persist cookies across requests as a normal web browser would. Enabled by default


### `follow_redirects` [plugins-filters-http-follow_redirects]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Should redirects be followed? Defaults to `true`


### `keepalive` [plugins-filters-http-keepalive]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Turn this on to enable HTTP keepalive support. We highly recommend setting `automatic_retries` to at least one with this to fix interactions with broken keepalive implementations.


### `password` [plugins-filters-http-password]

* Value type is [password](/reference/configuration-file-structure.md#password)
* There is no default value for this setting.

Password to be used in conjunction with the username for HTTP authentication.


### `pool_max` [plugins-filters-http-pool_max]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `50`

Max number of concurrent connections. Defaults to `50`


### `pool_max_per_route` [plugins-filters-http-pool_max_per_route]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `25`

Max number of concurrent connections to a single host. Defaults to `25`


### `proxy` [plugins-filters-http-proxy]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

If you’d like to use an HTTP proxy . This supports multiple configuration syntaxes:

1. Proxy host in form: `http://proxy.org:1234`
2. Proxy host in form: `{host => "proxy.org", port => 80, scheme => 'http', user => 'username@host', password => 'password'}`
3. Proxy host in form: `{url =>  'http://proxy.org:1234', user => 'username@host', password => 'password'}`


### `request_timeout` [plugins-filters-http-request_timeout]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `60`

Timeout (in seconds) for the entire request.


### `retry_non_idempotent` [plugins-filters-http-retry_non_idempotent]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

If `automatic_retries` is enabled this will cause non-idempotent HTTP verbs (such as POST) to be retried.


### `socket_timeout` [plugins-filters-http-socket_timeout]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `10`

Timeout (in seconds) to wait for data on the socket. Default is `10s`


### `ssl_certificate` [plugins-filters-http-ssl_certificate]

* Value type is [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting.

SSL certificate to use to authenticate the client. This certificate should be an OpenSSL-style X.509 certificate file.

::::{note}
This setting can be used only if [`ssl_key`](#plugins-filters-http-ssl_key) is set.
::::



### `ssl_certificate_authorities` [plugins-filters-http-ssl_certificate_authorities]

* Value type is a list of [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting

The .cer or .pem CA files to validate the server’s certificate.


### `ssl_cipher_suites` [plugins-filters-http-ssl_cipher_suites]

* Value type is a list of [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting

The list of cipher suites to use, listed by priorities. Supported cipher suites vary depending on the Java and protocol versions.


### `ssl_enabled` [plugins-filters-http-ssl_enabled]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Enable SSL/TLS secured communication. It must be `true` for other `ssl_` options to take effect.


### `ssl_key` [plugins-filters-http-ssl_key]

* Value type is [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting.

OpenSSL-style RSA private key that corresponds to the [`ssl_certificate`](#plugins-filters-http-ssl_certificate).

::::{note}
This setting can be used only if [`ssl_certificate`](#plugins-filters-http-ssl_certificate) is set.
::::



### `ssl_keystore_password` [plugins-filters-http-ssl_keystore_password]

* Value type is [password](/reference/configuration-file-structure.md#password)
* There is no default value for this setting.

Set the keystore password


### `ssl_keystore_path` [plugins-filters-http-ssl_keystore_path]

* Value type is [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting.

The keystore used to present a certificate to the server. It can be either `.jks` or `.p12`


### `ssl_keystore_type` [plugins-filters-http-ssl_keystore_type]

* Value can be any of: `jks`, `pkcs12`
* If not provided, the value will be inferred from the keystore filename.

The format of the keystore file. It must be either `jks` or `pkcs12`.


### `ssl_supported_protocols` [plugins-filters-http-ssl_supported_protocols]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Allowed values are: `'TLSv1.1'`, `'TLSv1.2'`, `'TLSv1.3'`
* Default depends on the JDK being used. With up-to-date Logstash, the default is `['TLSv1.2', 'TLSv1.3']`. `'TLSv1.1'` is not considered secure and is only provided for legacy applications.

List of allowed SSL/TLS versions to use when establishing a connection to the HTTP endpoint.

For Java 8 `'TLSv1.3'` is supported  only since **8u262** (AdoptOpenJDK), but requires that you set the `LS_JAVA_OPTS="-Djdk.tls.client.protocols=TLSv1.3"` system property in Logstash.

::::{note}
If you configure the plugin to use `'TLSv1.1'` on any recent JVM, such as the one packaged with Logstash, the protocol is disabled by default and needs to be enabled manually by changing `jdk.tls.disabledAlgorithms` in the **$JDK_HOME/conf/security/java.security** configuration file. That is, `TLSv1.1` needs to be removed from the list.
::::



### `ssl_truststore_password` [plugins-filters-http-ssl_truststore_password]

* Value type is [password](/reference/configuration-file-structure.md#password)
* There is no default value for this setting.

Set the truststore password


### `ssl_truststore_path` [plugins-filters-http-ssl_truststore_path]

* Value type is [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting.

The truststore to validate the server’s certificate. It can be either `.jks` or `.p12`.


### `ssl_truststore_type` [plugins-filters-http-ssl_truststore_type]

* Value can be any of: `jks`, `pkcs12`
* If not provided, the value will be inferred from the truststore filename.

The format of the truststore file. It must be either `jks` or `pkcs12`.


### `ssl_verification_mode` [plugins-filters-http-ssl_verification_mode]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Supported values are: `full`, `none`
* Default value is `full`

Controls the verification of server certificates. The `full` option verifies that the provided certificate is signed by a trusted authority (CA) and also that the server’s hostname (or IP address) matches the names identified within the certificate.

The `none` setting performs no verification of the server’s certificate. This mode disables many of the security benefits of SSL/TLS and should only be used after cautious consideration. It is primarily intended as a temporary diagnostic mechanism when attempting to resolve TLS errors. Using `none`  in production environments is strongly discouraged.


### `user` [plugins-filters-http-user]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Username to use with HTTP authentication for ALL requests. Note that you can also set this per-URL. If you set this you must also set the `password` option.


### `validate_after_inactivity` [plugins-filters-http-validate_after_inactivity]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `200`

How long to wait before checking for a stale connection to determine if a keepalive request is needed. Consider setting this value lower than the default, possibly to 0, if you get connection errors regularly.

This client is based on Apache Commons. Here’s how the [Apache Commons documentation](https://hc.apache.org/httpcomponents-client-ga/httpclient/apidocs/org/apache/http/impl/conn/PoolingHttpClientConnectionManager.md#setValidateAfterInactivity(int)) describes this option: "Defines period of inactivity in milliseconds after which persistent connections must be re-validated prior to being leased to the consumer. Non-positive value passed to this method disables connection validation. This check helps detect connections that have become stale (half-closed) while kept inactive in the pool."



## HTTP Filter Obsolete Configuration Options [plugins-filters-http-obsolete-options]

::::{warning}
As of version `2.0.0` of this plugin, some configuration options have been replaced. The plugin will fail to start if it contains any of these obsolete options.
::::


| Setting | Replaced by |
| --- | --- |
| cacert | [`ssl_certificate_authorities`](#plugins-filters-http-ssl_certificate_authorities) |
| client_cert | [`ssl_certificate`](#plugins-filters-http-ssl_certificate) |
| client_key | [`ssl_key`](#plugins-filters-http-ssl_key) |
| keystore | [`ssl_keystore_path`](#plugins-filters-http-ssl_keystore_path) |
| keystore_password | [`ssl_keystore_password`](#plugins-filters-http-ssl_keystore_password) |
| keystore_type | [`ssl_keystore_type`](#plugins-filters-http-ssl_keystore_type) |
| truststore | [`ssl_truststore_path`](#plugins-filters-http-ssl_truststore_path) |
| truststore_password | [`ssl_truststore_password`](#plugins-filters-http-ssl_truststore_password) |
| truststore_type | [`ssl_truststore_type`](#plugins-filters-http-ssl_truststore_type) |


## Common options [plugins-filters-http-common-options]

These configuration options are supported by all filter plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`add_field`](#plugins-filters-http-add_field) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`add_tag`](#plugins-filters-http-add_tag) | [array](/reference/configuration-file-structure.md#array) | No |
| [`enable_metric`](#plugins-filters-http-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-filters-http-id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`periodic_flush`](#plugins-filters-http-periodic_flush) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`remove_field`](#plugins-filters-http-remove_field) | [array](/reference/configuration-file-structure.md#array) | No |
| [`remove_tag`](#plugins-filters-http-remove_tag) | [array](/reference/configuration-file-structure.md#array) | No |

### `add_field` [plugins-filters-http-add_field]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

If this filter is successful, add any arbitrary fields to this event. Field names can be dynamic and include parts of the event using the `%{{field}}`.

Example:

```json
    filter {
      http {
        add_field => { "foo_%{somefield}" => "Hello world, from %{host}" }
      }
    }
```

```json
    # You can also add multiple fields at once:
    filter {
      http {
        add_field => {
          "foo_%{somefield}" => "Hello world, from %{host}"
          "new_field" => "new_static_value"
        }
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would add field `foo_hello` if it is present, with the value above and the `%{{host}}` piece replaced with that value from the event. The second example would also add a hardcoded field.


### `add_tag` [plugins-filters-http-add_tag]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

If this filter is successful, add arbitrary tags to the event. Tags can be dynamic and include parts of the event using the `%{{field}}` syntax.

Example:

```json
    filter {
      http {
        add_tag => [ "foo_%{somefield}" ]
      }
    }
```

```json
    # You can also add multiple tags at once:
    filter {
      http {
        add_tag => [ "foo_%{somefield}", "taggedy_tag"]
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would add a tag `foo_hello` (and the second example would of course add a `taggedy_tag` tag).


### `enable_metric` [plugins-filters-http-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance. By default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-filters-http-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type, for example, if you have 2 http filters. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
    filter {
      http {
        id => "ABC"
      }
    }
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::



### `periodic_flush` [plugins-filters-http-periodic_flush]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Call the filter flush method at regular interval. Optional.


### `remove_field` [plugins-filters-http-remove_field]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

If this filter is successful, remove arbitrary fields from this event. Fields names can be dynamic and include parts of the event using the `%{{field}}` Example:

```json
    filter {
      http {
        remove_field => [ "foo_%{somefield}" ]
      }
    }
```

```json
    # You can also remove multiple fields at once:
    filter {
      http {
        remove_field => [ "foo_%{somefield}", "my_extraneous_field" ]
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would remove the field with name `foo_hello` if it is present. The second example would remove an additional, non-dynamic field.


### `remove_tag` [plugins-filters-http-remove_tag]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

If this filter is successful, remove arbitrary tags from the event. Tags can be dynamic and include parts of the event using the `%{{field}}` syntax.

Example:

```json
    filter {
      http {
        remove_tag => [ "foo_%{somefield}" ]
      }
    }
```

```json
    # You can also remove multiple tags at once:
    filter {
      http {
        remove_tag => [ "foo_%{somefield}", "sad_unwanted_tag"]
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would remove the tag `foo_hello` if it is present. The second example would remove a sad, unwanted tag as well.
