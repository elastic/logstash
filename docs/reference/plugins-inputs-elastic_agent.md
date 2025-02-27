---
navigation_title: "elastic_agent"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-inputs-elastic_agent.html
---

# Elastic Agent input plugin [plugins-inputs-elastic_agent]

::::{note}
The `input-elastic_agent` plugin is the next generation of the `input-beats` plugin. They currently share code and a [common codebase](https://github.com/logstash-plugins/logstash-input-beats).
::::



* Plugin version: v7.0.0
* Released on: 2024-12-02
* [Changelog](https://github.com/logstash-plugins/logstash-input-beats/blob/v7.0.0/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://docs/reference/input-elastic_agent-index.md).

## Getting help [_getting_help_13]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-input-elastic_agent). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_14]

This input plugin enables Logstash to receive events from the Elastic Agent framework.

The following example shows how to configure Logstash to listen on port 5044 for incoming Elastic Agent connections and to index into Elasticsearch.

```sh
input {
  elastic_agent {
    port => 5044
  }
}

output {
  elasticsearch {
    hosts => ["http://localhost:9200"]
    data_stream => "true"
  }
}
```

Events indexed into Elasticsearch with the Logstash configuration shown here will be similar to events directly indexed by Elastic Agent into Elasticsearch.

### Memory usage [plugins-inputs-elastic_agent-memory]

This plugin uses "off-heap" direct memory in addition to heap memory. By default, a JVM’s off-heap direct memory limit is the same as the heap size. For example, setting `-Xmx10G` without setting the direct memory limit will allocate `10GB` for heap and an additional `10GB` for direct memory, for a total of `20GB` allocated. You can set the amount of direct memory with `-XX:MaxDirectMemorySize` in [Logstash JVM Settings](/reference/jvm-settings.md). Consider setting direct memory to half of the heap size. Setting direct memory too low decreases the performance of ingestion.

::::{note}
Be sure that heap and direct memory combined does not exceed the total memory available on the server to avoid an OutOfDirectMemoryError
::::




## Event enrichment and the Elastic Common Schema (ECS) [plugins-inputs-elastic_agent-ecs_metadata]

When decoding Elastic Agent events, this plugin enriches each event with metadata about the event’s source, making this information available during further processing. You can use the [`enrich`](#plugins-inputs-elastic_agent-enrich) option to activate or deactivate individual enrichment categories.

The location of these enrichment fields depends on whether [ECS compatibility mode](#plugins-inputs-elastic_agent-ecs_compatibility) is enabled:

* When ECS compatibility is *enabled*, enrichment fields are added in an ECS-compatible structure.
* When ECS compatibility is *disabled*, enrichment fields are added in a way that is backward-compatible with this plugin, but is known to clash with the Elastic Common Schema.

| ECS `v1`, `v8` | ECS `disabled` | Description |
| --- | --- | --- |
| [@metadata][input][beats][host][name] | [host] | *Name or address of the Elastic Agent host* |
| [@metadata][input][beats][host][ip] | [@metadata][ip_address] | *IP address of the Elastic Agent client that connected to this input* |

| ECS `v1`, `v8` | ECS `disabled` | Description |
| --- | --- | --- |
| [@metadata][tls_peer][status] | [@metadata][tls_peer][status] | *Contains "verified" or "unverified" label; available when SSL is enabled.* |
| [@metadata][input][beats][tls][version_protocol] | [@metadata][tls_peer][protocol] | *Contains the TLS version used (such as `TLSv1.2`); available when SSL status is "verified"* |
| [@metadata][input][beats][tls][client][subject] | [@metadata][tls_peer][subject] | *Contains the identity name of the remote end (such as `CN=artifacts-no-kpi.elastic.co`); available when SSL status is "verified"* |
| [@metadata][input][beats][tls][cipher] | [@metadata][tls_peer][cipher_suite] | *Contains the name of cipher suite used (such as `TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256`); available when SSL status is "verified"* |

| ECS `v1`, `v8` | ECS `disabled` | Description |
| --- | --- | --- |
| [tag] | [tag] | *Contains `beats_input_codec_XXX_applied` where `XXX` is the name of the codec* |
| [event][original] | *N/A* | *When ECS is enabled, even if `[event][original]` field does not already exist on the event being processed, this plugin’s **default codec** ensures that the field is populated using the bytes as-processed.* |


## Elastic Agent input configuration options [plugins-inputs-elastic_agent-options]

This plugin supports the following configuration options plus the [Common options](#plugins-inputs-elastic_agent-common-options) described later.

::::{note}
As of version `7.0.0` of this plugin, a number of previously deprecated settings related to SSL have been removed. Please check out [Beats Input Obsolete Configuration Options](#plugins-inputs-elastic_agent-obsolete-options) for details.
::::


| Setting | Input type | Required |
| --- | --- | --- |
| [`add_hostname`](#plugins-inputs-elastic_agent-add_hostname) | [boolean](/reference/configuration-file-structure.md#boolean) | *Deprecated* |
| [`client_inactivity_timeout`](#plugins-inputs-elastic_agent-client_inactivity_timeout) | [number](/reference/configuration-file-structure.md#number) | No |
| [`ecs_compatibility`](#plugins-inputs-elastic_agent-ecs_compatibility) | [string](/reference/configuration-file-structure.md#string) | No |
| [`enrich`](#plugins-inputs-elastic_agent-enrich) | [string](/reference/configuration-file-structure.md#string) | No |
| [`event_loop_threads`](#plugins-inputs-elastic_agent-event_loop_threads) | [number](/reference/configuration-file-structure.md#number) | No |
| [`executor_threads`](#plugins-inputs-elastic_agent-executor_threads) | [number](/reference/configuration-file-structure.md#number) | No |
| [`host`](#plugins-inputs-elastic_agent-host) | [string](/reference/configuration-file-structure.md#string) | No |
| [`include_codec_tag`](#plugins-inputs-elastic_agent-include_codec_tag) | [boolean](/reference/configuration-file-structure.md#boolean) | *Deprecated* |
| [`port`](#plugins-inputs-elastic_agent-port) | [number](/reference/configuration-file-structure.md#number) | Yes |
| [`ssl_certificate`](#plugins-inputs-elastic_agent-ssl_certificate) | a valid filesystem path | No |
| [`ssl_certificate_authorities`](#plugins-inputs-elastic_agent-ssl_certificate_authorities) | [array](/reference/configuration-file-structure.md#array) | No |
| [`ssl_cipher_suites`](#plugins-inputs-elastic_agent-ssl_cipher_suites) | [array](/reference/configuration-file-structure.md#array) | No |
| [`ssl_client_authentication`](#plugins-inputs-elastic_agent-ssl_client_authentication) | [string](/reference/configuration-file-structure.md#string), one of `["none", "optional", "required"]` | No |
| [`ssl_enabled`](#plugins-inputs-elastic_agent-ssl_enabled) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`ssl_handshake_timeout`](#plugins-inputs-elastic_agent-ssl_handshake_timeout) | [number](/reference/configuration-file-structure.md#number) | No |
| [`ssl_key`](#plugins-inputs-elastic_agent-ssl_key) | a valid filesystem path | No |
| [`ssl_key_passphrase`](#plugins-inputs-elastic_agent-ssl_key_passphrase) | [password](/reference/configuration-file-structure.md#password) | No |
| [`ssl_supported_protocols`](#plugins-inputs-elastic_agent-ssl_supported_protocols) | [array](/reference/configuration-file-structure.md#array) | No |

Also see [Common options](#plugins-inputs-elastic_agent-common-options) for a list of options supported by all input plugins.

 

### `add_hostname` [plugins-inputs-elastic_agent-add_hostname]

::::{admonition} Deprecated in 6.0.0.
:class: warning

The default value has been changed to `false`. In 7.0.0 this setting will be removed
::::


* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Flag to determine whether to add `host` field to event using the value supplied by the Elastic Agent in the `hostname` field.


### `client_inactivity_timeout` [plugins-inputs-elastic_agent-client_inactivity_timeout]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `60`

Close Idle clients after X seconds of inactivity.


### `ecs_compatibility` [plugins-inputs-elastic_agent-ecs_compatibility]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Supported values are:

    * `disabled`: unstructured connection metadata added at root level
    * `v1`: structured connection metadata added under ECS v1 compliant namespaces
    * `v8`: structured connection metadata added under ECS v8 compliant namespaces

* Default value depends on which version of Logstash is running:

    * When Logstash provides a `pipeline.ecs_compatibility` setting, its value is used as the default
    * Otherwise, the default value is `disabled`.


Refer to [ECS mapping](#plugins-inputs-elastic_agent-ecs_metadata) for detailed information.


### `enrich` [plugins-inputs-elastic_agent-enrich]

* Value type is [string](/reference/configuration-file-structure.md#string)

    * An [array](/reference/configuration-file-structure.md#array) can also be provided
    * Configures which enrichments are applied to each event
    * Default value is `[codec_metadata, source_metadata]` that may be extended in future versions of this plugin to include additional enrichments.
    * Supported values are:

        | Enrichment | Description |
        | --- | --- |
        |  codec_metadata | Information about how the codec transformed a sequence of bytes into                      this Event, such as *which* codec was used. Also, if no codec is                      explicitly specified, *excluding* `codec_metadata` from `enrich` will                      disable `ecs_compatibility` for this plugin. |
        |  source_metadata | Information about the *source* of the event, such as the IP address                      of the inbound connection this input received the event from |
        |  ssl_peer_metadata | Detailed information about the *SSL peer* we received the event from,                      such as identity information from the SSL client certificate that was                      presented when establishing a connection to this input |
        |  all | *alias* to include *all* available enrichments (including additional                      enrichments introduced in future versions of this plugin) |
        |  none | *alias* to *exclude* all available enrichments. Note that, *explicitly*                      defining codec with this option will not disable the `ecs_compatibility`,                      instead it relies on pipeline or codec `ecs_compatibility` configuration. |


**Example:**

This configuration disables *all* enrichments:

```
input {
  beats {
    port => 5044
    enrich => none
  }
}
```

Or, to explicitly enable *only* `source_metadata` and `ssl_peer_metadata` (disabling all others):

```
input {
  beats {
    port => 5044
    enrich => [source_metadata, ssl_peer_metadata]
  }
}
```


### `event_loop_threads` [plugins-inputs-elastic_agent-event_loop_threads]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Defaults to 0.

When setting `0`, the actual default is `available_processors * 2`

This is an expert-level setting, and generally should not need to be set Elastic Agent plugin is implemented based on a non-blocking mechanism, requiring a number of event loop and executor threads. The event loop threads are responsible to communicate with clients (accept incoming connections, enqueue/dequeue tasks and respond) and executor threads handle tasks. This configuration intends to limit or increase the number of threads to be created for the event loop. See [`executor_threads`](#plugins-inputs-elastic_agent-executor_threads) configuration if you need to set executor threads count.


### `executor_threads` [plugins-inputs-elastic_agent-executor_threads]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is equal to the number of CPU cores (1 executor thread per CPU core).

The number of threads to be used to process incoming Elastic Agent requests. By default, the Elastic Agent input creates a number of threads equal to the number of CPU cores. These threads handle incoming connections, reading from established sockets, and executing most of the tasks related to network connection management. Parsing the Lumberjack protocol is offloaded to a dedicated thread pool.

Generally you don’t need to touch this setting. In case you are sending very large events and observing "OutOfDirectMemory" exceptions, you may want to reduce this number to half or 1/4 of the CPU cores. This change reduces the number of threads decompressing batches of data into direct memory. However, this will only be a mitigating tweak, as the proper solution may require resizing your Logstash deployment, either by increasing number of Logstash nodes or increasing the JVM’s Direct Memory.


### `host` [plugins-inputs-elastic_agent-host]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"0.0.0.0"`

The IP address to listen on.


### `include_codec_tag` [plugins-inputs-elastic_agent-include_codec_tag]

::::{admonition} Deprecated in 6.5.0.
:class: warning

Replaced by [`enrich`](#plugins-inputs-elastic_agent-enrich)
::::


* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`


### `port` [plugins-inputs-elastic_agent-port]

* This is a required setting.
* Value type is [number](/reference/configuration-file-structure.md#number)
* There is no default value for this setting.

The port to listen on.


### `ssl_certificate` [plugins-inputs-elastic_agent-ssl_certificate]

* Value type is [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting.

SSL certificate to use.


### `ssl_certificate_authorities` [plugins-inputs-elastic_agent-ssl_certificate_authorities]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

Validate client certificates against these authorities. You can define multiple files or paths. All the certificates will be read and added to the trust store. You need to configure the [`ssl_client_authentication`](#plugins-inputs-elastic_agent-ssl_client_authentication) to `optional` or `required` to enable the verification.


### `ssl_cipher_suites` [plugins-inputs-elastic_agent-ssl_cipher_suites]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `['TLS_AES_256_GCM_SHA384', 'TLS_AES_128_GCM_SHA256', 'TLS_CHACHA20_POLY1305_SHA256', 'TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384', 'TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384', 'TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256', 'TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256', 'TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256', 'TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256', 'TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384', 'TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384', 'TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256', 'TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256']`

The list of cipher suites to use, listed by priorities. This default list applies for OpenJDK 11.0.14 and higher. For older JDK versions, the default list includes only suites supported by that version. For example, the ChaCha20 family of ciphers is not supported in older versions.


### `ssl_client_authentication` [plugins-inputs-elastic_agent-ssl_client_authentication]

* Value can be any of: `none`, `optional`, `required`
* Default value is `"none"`

Controls the server’s behavior in regard to requesting a certificate from client connections: `required` forces a client to present a certificate, while `optional` requests a client certificate but the client is not required to present one. Defaults to `none`, which disables the client authentication.

When mutual TLS is enabled (`required` or `optional`), the certificate presented by the client must be signed by trusted [`ssl_certificate_authorities`](#plugins-inputs-elastic_agent-ssl_certificate_authorities) (CAs). Please note that the server does not validate the client certificate CN (Common Name) or SAN (Subject Alternative Name).

::::{note}
This setting can be used only if [`ssl_certificate_authorities`](#plugins-inputs-elastic_agent-ssl_certificate_authorities) is set.
::::



### `ssl_enabled` [plugins-inputs-elastic_agent-ssl_enabled]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Events are by default sent in plain text. You can enable encryption by setting `ssl_enabled` to true and configuring the [`ssl_certificate`](#plugins-inputs-elastic_agent-ssl_certificate) and [`ssl_key`](#plugins-inputs-elastic_agent-ssl_key) options.


### `ssl_handshake_timeout` [plugins-inputs-elastic_agent-ssl_handshake_timeout]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `10000`

Time in milliseconds for an incomplete ssl handshake to timeout


### `ssl_key` [plugins-inputs-elastic_agent-ssl_key]

* Value type is [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting.

SSL key to use. This key must be in the PKCS8 format and PEM encoded. You can use the [openssl pkcs8](https://www.openssl.org/docs/man1.1.1/man1/openssl-pkcs8.md) command to complete the conversion. For example, the command to convert a PEM encoded PKCS1 private key to a PEM encoded, non-encrypted PKCS8 key is:

```sh
openssl pkcs8 -inform PEM -in path/to/logstash.key -topk8 -nocrypt -outform PEM -out path/to/logstash.pkcs8.key
```


### `ssl_key_passphrase` [plugins-inputs-elastic_agent-ssl_key_passphrase]

* Value type is [password](/reference/configuration-file-structure.md#password)
* There is no default value for this setting.

SSL key passphrase to use.


### `ssl_supported_protocols` [plugins-inputs-elastic_agent-ssl_supported_protocols]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Allowed values are: `'TLSv1.1'`, `'TLSv1.2'`, `'TLSv1.3'`
* Default depends on the JDK being used. With up-to-date Logstash, the default is `['TLSv1.2', 'TLSv1.3']`. `'TLSv1.1'` is not considered secure and is only provided for legacy applications.

List of allowed SSL/TLS versions to use when establishing a connection to the HTTP endpoint.

For Java 8 `'TLSv1.3'` is supported  only since **8u262** (AdoptOpenJDK), but requires that you set the `LS_JAVA_OPTS="-Djdk.tls.client.protocols=TLSv1.3"` system property in Logstash.

::::{note}
If you configure the plugin to use `'TLSv1.1'` on any recent JVM, such as the one packaged with Logstash, the protocol is disabled by default and needs to be enabled manually by changing `jdk.tls.disabledAlgorithms` in the **$JDK_HOME/conf/security/java.security** configuration file. That is, `TLSv1.1` needs to be removed from the list.
::::




## Beats Input Obsolete Configuration Options [plugins-inputs-elastic_agent-obsolete-options]

::::{warning}
As of version `7.0.0` of this plugin, some configuration options have been replaced. The plugin will fail to start if it contains any of these obsolete options.
::::


| Setting | Replaced by |
| --- | --- |
| cipher_suites | [`ssl_cipher_suites`](#plugins-inputs-elastic_agent-ssl_cipher_suites) |
| ssl | [`ssl_enabled`](#plugins-inputs-elastic_agent-ssl_enabled) |
| ssl_peer_metadata | [`enrich`](#plugins-inputs-elastic_agent-enrich) |
| ssl_verify_mode | [`ssl_client_authentication`](#plugins-inputs-elastic_agent-ssl_client_authentication) |
| tls_max_version | [`ssl_supported_protocols`](#plugins-inputs-elastic_agent-ssl_supported_protocols) |
| tls_min_version | [`ssl_supported_protocols`](#plugins-inputs-elastic_agent-ssl_supported_protocols) |


## Common options [plugins-inputs-elastic_agent-common-options]

These configuration options are supported by all input plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`add_field`](#plugins-inputs-elastic_agent-add_field) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`codec`](#plugins-inputs-elastic_agent-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-inputs-elastic_agent-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-inputs-elastic_agent-id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`tags`](#plugins-inputs-elastic_agent-tags) | [array](/reference/configuration-file-structure.md#array) | No |
| [`type`](#plugins-inputs-elastic_agent-type) | [string](/reference/configuration-file-structure.md#string) | No |

### `add_field` [plugins-inputs-elastic_agent-add_field]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

Add a field to an event


### `codec` [plugins-inputs-elastic_agent-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for input data. Input codecs are a convenient method for decoding your data before it enters the input, without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-inputs-elastic_agent-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance by default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-inputs-elastic_agent-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type, for example, if you have 2 elastic_agent inputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
input {
  elastic_agent {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::



### `tags` [plugins-inputs-elastic_agent-tags]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

Add any number of arbitrary tags to your event.

This can help with processing later.


### `type` [plugins-inputs-elastic_agent-type]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a `type` field to all events handled by this input.

Types are used mainly for filter activation.

The type is stored as part of the event itself, so you can also use the type to search for it in Kibana.

If you try to set a type on an event that already has one (for example when you send an event from a shipper to an indexer) then a new input will not override the existing type. A type set at the shipper stays with that event for its life even when sent to another Logstash server.
