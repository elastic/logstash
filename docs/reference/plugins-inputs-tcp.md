---
navigation_title: "tcp"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-inputs-tcp.html
---

# Tcp input plugin [plugins-inputs-tcp]


* Plugin version: v7.0.0
* Released on: 2025-01-10
* [Changelog](https://github.com/logstash-plugins/logstash-input-tcp/blob/v7.0.0/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://docs/reference/input-tcp-index.md).

## Getting help [_getting_help_57]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-input-tcp). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_57]

Read events over a TCP socket.

Like stdin and file inputs, each event is assumed to be one line of text.

Can either accept connections from clients or connect to a server, depending on `mode`.

### Accepting log4j2 logs [_accepting_log4j2_logs]

Log4j2 can send JSON over a socket, and we can use that combined with our tcp input to accept the logs.

First, we need to configure your application to send logs in JSON over a socket. The following log4j2.xml accomplishes this task.

Note, you will want to change the `host` and `port` settings in this configuration to match your needs.

```
<Configuration>
  <Appenders>
     <Socket name="Socket" host="localhost" port="12345">
       <JsonLayout compact="true" eventEol="true" />
    </Socket>
  </Appenders>
  <Loggers>
    <Root level="info">
      <AppenderRef ref="Socket"/>
    </Root>
  </Loggers>
</Configuration>
```
To accept this in Logstash, you will want tcp input and a date filter:

```
input {
  tcp {
    port => 12345
    codec => json
  }
}
```
and add a date filter to take log4j2’s `timeMillis` field and use it as the event timestamp

```
filter {
  date {
    match => [ "timeMillis", "UNIX_MS" ]
  }
}
```


## Event Metadata and the Elastic Common Schema (ECS) [plugins-inputs-tcp-ecs_metadata]

In addition to decoding the events, this input will add metadata about the TCP connection itself to each event. This can be helpful when applications are configured to send events directly to this input’s TCP listener without including information about themselves.

Historically, this metadata was added to a variety of non-standard top-level fields, which had the potential to create confusion and schema conflicts downstream. With ECS compatibility mode, we can ensure a pipeline still has access to this metadata throughout the event’s lifecycle without polluting the top-level namespace.

| Metadata Group | ecs: `v1`, `v8` | ecs: `disabled` |
| --- | --- | --- |
| Source Metadata from the TCP connectionon which events are being received, includingthe sender’s name, ip, and outbound port. | [@metadata][input][tcp][source][name] | [host] |
| [@metadata][input][tcp][source][ip] | [@metadata][ip_address] |
| [@metadata][input][tcp][source][port] | [port] |
| Proxy Metadata from a proxied TCP connection.Available when receiving events by proxy and`proxy_protocol => true` | [@metadata][input][tcp][proxy][ip] | [proxy_host] |
| [@metadata][input][tcp][proxy][port] | [proxy_port] |
| SSL Subject Metadata from a secured TCPconnection. Available when `ssl_enabled => true`AND `ssl_client_authentication => 'optional' or 'required'` | [@metadata][input][tcp][ssl][subject] | [sslsubject] |

For example, the Elastic Common Schema reserves the [top-level `host` field](ecs://docs/reference/ecs-host.md) for information about the host on which the event happened. If an event is missing this metadata, it can be copied into place from the source TCP connection metadata that has been added to the event:

```txt
filter {
  if [@metadata][input][tcp][source] and ![host] {
    mutate {
      copy => {
        "[@metadata][input][tcp][source][name]" => "[host][name]"
        "[@metadata][input][tcp][source][ip]"   => "[host][ip]"
      }
    }
  }
}
```


## Tcp Input Configuration Options [plugins-inputs-tcp-options]

This plugin supports the following configuration options plus the [Common options](#plugins-inputs-tcp-common-options) described later.

::::{note}
As of version `7.0.0` of this plugin, a number of previously deprecated settings related to SSL have been removed. Please see the [TCP Input Obsolete Configuration Options](#plugins-inputs-tcp-obsolete-options) for more details.
::::


| Setting | Input type | Required |
| --- | --- | --- |
| [`dns_reverse_lookup_enabled`](#plugins-inputs-tcp-dns_reverse_lookup_enabled) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`ecs_compatibility`](#plugins-inputs-tcp-ecs_compatibility) | [string](/reference/configuration-file-structure.md#string) | No |
| [`host`](#plugins-inputs-tcp-host) | [string](/reference/configuration-file-structure.md#string) | No |
| [`mode`](#plugins-inputs-tcp-mode) | [string](/reference/configuration-file-structure.md#string), one of `["server", "client"]` | No |
| [`port`](#plugins-inputs-tcp-port) | [number](/reference/configuration-file-structure.md#number) | Yes |
| [`proxy_protocol`](#plugins-inputs-tcp-proxy_protocol) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`ssl_certificate`](#plugins-inputs-tcp-ssl_certificate) | a valid filesystem path | No |
| [`ssl_certificate_authorities`](#plugins-inputs-tcp-ssl_certificate_authorities) | [array](/reference/configuration-file-structure.md#array) | No |
| [`ssl_cipher_suites`](#plugins-inputs-tcp-ssl_cipher_suites) | [string](/reference/configuration-file-structure.md#string) | No |
| [`ssl_client_authentication`](#plugins-inputs-tcp-ssl_client_authentication) | [string](/reference/configuration-file-structure.md#string), one of `["none", "optional", "required"]` | No |
| [`ssl_enabled`](#plugins-inputs-tcp-ssl_enabled) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`ssl_extra_chain_certs`](#plugins-inputs-tcp-ssl_extra_chain_certs) | [array](/reference/configuration-file-structure.md#array) | No |
| [`ssl_key`](#plugins-inputs-tcp-ssl_key) | a valid filesystem path | No |
| [`ssl_key_passphrase`](#plugins-inputs-tcp-ssl_key_passphrase) | [password](/reference/configuration-file-structure.md#password) | No |
| [`ssl_supported_protocols`](#plugins-inputs-tcp-ssl_supported_protocols) | [string](/reference/configuration-file-structure.md#string) | No |
| [`ssl_verification_mode`](#plugins-inputs-tcp-ssl_verification_mode) | [string](/reference/configuration-file-structure.md#string), one of `["full", "none"]` | No |
| [`tcp_keep_alive`](#plugins-inputs-tcp-tcp_keep_alive) | [boolean](/reference/configuration-file-structure.md#boolean) | No |

Also see [Common options](#plugins-inputs-tcp-common-options) for a list of options supported by all input plugins.

 

### `dns_reverse_lookup_enabled` [plugins-inputs-tcp-dns_reverse_lookup_enabled]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

It is possible to avoid DNS reverse-lookups by disabling this setting. If disabled, the address metadata that is added to events will contain the source address as-specified at the TCP layer and IPs will not be resolved to hostnames.


### `ecs_compatibility` [plugins-inputs-tcp-ecs_compatibility]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Supported values are:

    * `disabled`: unstructured connection metadata added at root level
    * `v1`,`v8`: structured connection metadata added under `[@metadata][input][tcp]`

* Default value depends on which version of Logstash is running:

    * When Logstash provides a `pipeline.ecs_compatibility` setting, its value is used as the default
    * Otherwise, the default value is `disabled`.


Controls this plugin’s compatibility with the [Elastic Common Schema (ECS)][Elastic Common Schema (ECS)](ecs://docs/reference/index.md)). The value of this setting affects the [placement of a TCP connection’s metadata](#plugins-inputs-tcp-ecs_metadata) on events.


### `host` [plugins-inputs-tcp-host]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"0.0.0.0"`

When mode is `server`, the address to listen on. When mode is `client`, the address to connect to.


### `mode` [plugins-inputs-tcp-mode]

* Value can be any of: `server`, `client`
* Default value is `"server"`

Mode to operate in. `server` listens for client connections, `client` connects to a server.


### `port` [plugins-inputs-tcp-port]

* This is a required setting.
* Value type is [number](/reference/configuration-file-structure.md#number)
* There is no default value for this setting.

When mode is `server`, the port to listen on. When mode is `client`, the port to connect to.


### `proxy_protocol` [plugins-inputs-tcp-proxy_protocol]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Proxy protocol support, only v1 is supported at this time [http://www.haproxy.org/download/1.5/doc/proxy-protocol.txt](http://www.haproxy.org/download/1.5/doc/proxy-protocol.txt)


### `ssl_certificate` [plugins-inputs-tcp-ssl_certificate]

* Value type is [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting.

Path to certificate in PEM format. This certificate will be presented to the other part of the TLS connection.


### `ssl_certificate_authorities` [plugins-inputs-tcp-ssl_certificate_authorities]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

Validate client certificate or certificate chain against these authorities. You can define multiple files or paths. All the certificates will be read and added to the trust store.


### `ssl_cipher_suites` [plugins-inputs-tcp-ssl_cipher_suites]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value includes *all* cipher suites enabled by the JDK and depends on JDK configuration

Supported cipher suites vary depending on Java version used, and entries look like `TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384`. For more information, see Oracle’s [JDK SunJSSE provider documentation](https://docs.oracle.com/en/java/javase/11/security/oracle-providers.md#GUID-7093246A-31A3-4304-AC5F-5FB6400405E2) and the table of supported [Java cipher suite names](https://docs.oracle.com/en/java/javase/11/docs/specs/security/standard-names.md#jsse-cipher-suite-names).

::::{note}
To check the supported cipher suites locally run the following script: `$LS_HOME/bin/ruby -e 'p javax.net.ssl.SSLServerSocketFactory.getDefault.getSupportedCipherSuites'`.
::::



### `ssl_client_authentication` [plugins-inputs-tcp-ssl_client_authentication]

* Value can be any of: `none`, `optional`, `required`
* Default value is `required`

Controls the server’s behavior in regard to requesting a certificate from client connections: `none` disables the client authentication. `required` forces a client to present a certificate, while `optional` requests a client certificate but the client is not required to present one.

When mutual TLS is enabled (`optional` or `required`), the certificate presented by the client must be signed by trusted [`ssl_certificate_authorities`](#plugins-inputs-tcp-ssl_certificate_authorities) (CAs). Please note that the server does not validate the client certificate CN (Common Name) or SAN (Subject Alternative Name).

::::{note}
This setting can be used only if [`mode`](#plugins-inputs-tcp-mode) is `server` and [`ssl_certificate_authorities`](#plugins-inputs-tcp-ssl_certificate_authorities) is set.
::::



### `ssl_enabled` [plugins-inputs-tcp-ssl_enabled]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Enable SSL (must be set for other `ssl_` options to take effect).


### `ssl_extra_chain_certs` [plugins-inputs-tcp-ssl_extra_chain_certs]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

An Array of paths to extra X509 certificates. These are used together with the certificate to construct the certificate chain presented to the client.


### `ssl_key` [plugins-inputs-tcp-ssl_key]

* Value type is [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting.

The path to the private key corresponding to the specified certificate (PEM format).


### `ssl_key_passphrase` [plugins-inputs-tcp-ssl_key_passphrase]

* Value type is [password](/reference/configuration-file-structure.md#password)
* Default value is `nil`

SSL key passphrase for the private key.


### `ssl_supported_protocols` [plugins-inputs-tcp-ssl_supported_protocols]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Allowed values are: `'TLSv1.1'`, `'TLSv1.2'`, `'TLSv1.3'`
* Default depends on the JDK being used. With up-to-date Logstash, the default is `['TLSv1.2', 'TLSv1.3']`. `'TLSv1.1'` is not considered secure and is only provided for legacy applications.

List of allowed SSL/TLS versions to use when establishing a secure connection.

::::{note}
If you configure the plugin to use `'TLSv1.1'` on any recent JVM, such as the one packaged with Logstash, the protocol is disabled by default and needs to be enabled manually by changing `jdk.tls.disabledAlgorithms` in the **$JDK_HOME/conf/security/java.security** configuration file. That is, `TLSv1.1` needs to be removed from the list.
::::



### `ssl_verification_mode` [plugins-inputs-tcp-ssl_verification_mode]

* Value can be any of: `full`, `none`
* Default value is `full`

Defines how to verify the certificates presented by another party in the TLS connection:

`full` validates that the server certificate has an issue date that’s within the not_before and not_after dates; chains to a trusted Certificate Authority (CA), and has a hostname or IP address that matches the names within the certificate.

`none` performs no certificate validation.

This setting can be used only if [`mode`](#plugins-inputs-tcp-mode) is `client`.

::::{warning}
Setting certificate verification to `none` disables many security benefits of SSL/TLS, which is very dangerous. For more information on disabling certificate verification please read [https://www.cs.utexas.edu/~shmat/shmat_ccs12.pdf](https://www.cs.utexas.edu/~shmat/shmat_ccs12.pdf)
::::



### `tcp_keep_alive` [plugins-inputs-tcp-tcp_keep_alive]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Instruct the socket to use TCP keep alive. If it’s `true` then the underlying socket will use the OS defaults settings for keep alive. If it’s `false` it doesn’t configure any keep alive setting for the underlying socket.



## TCP Input Obsolete Configuration Options [plugins-inputs-tcp-obsolete-options]

::::{warning}
As of version `7.0.0` of this plugin, some configuration options have been replaced. The plugin will fail to start if it contains any of these obsolete options.
::::


| Setting | Replaced by |
| --- | --- |
| ssl_cert | [`ssl_certificate`](#plugins-inputs-tcp-ssl_certificate) |
| ssl_enable | [`ssl_enabled`](#plugins-inputs-tcp-ssl_enabled) |
| ssl_verify | [`ssl_client_authentication`](#plugins-inputs-tcp-ssl_client_authentication) in `server` mode and [`ssl_verification_mode`](#plugins-inputs-tcp-ssl_verification_mode) in `client` mode |


## Common options [plugins-inputs-tcp-common-options]

These configuration options are supported by all input plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`add_field`](#plugins-inputs-tcp-add_field) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`codec`](#plugins-inputs-tcp-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-inputs-tcp-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-inputs-tcp-id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`tags`](#plugins-inputs-tcp-tags) | [array](/reference/configuration-file-structure.md#array) | No |
| [`type`](#plugins-inputs-tcp-type) | [string](/reference/configuration-file-structure.md#string) | No |

### `add_field` [plugins-inputs-tcp-add_field]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

Add a field to an event


### `codec` [plugins-inputs-tcp-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"line"`

The codec used for input data. Input codecs are a convenient method for decoding your data before it enters the input, without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-inputs-tcp-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance by default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-inputs-tcp-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type, for example, if you have 2 tcp inputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
input {
  tcp {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::



### `tags` [plugins-inputs-tcp-tags]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

Add any number of arbitrary tags to your event.

This can help with processing later.


### `type` [plugins-inputs-tcp-type]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a `type` field to all events handled by this input.

Types are used mainly for filter activation.

The type is stored as part of the event itself, so you can also use the type to search for it in Kibana.

If you try to set a type on an event that already has one (for example when you send an event from a shipper to an indexer) then a new input will not override the existing type. A type set at the shipper stays with that event for its life even when sent to another Logstash server.



