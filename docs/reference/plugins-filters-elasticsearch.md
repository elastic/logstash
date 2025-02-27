---
navigation_title: "elasticsearch"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-filters-elasticsearch.html
---

# Elasticsearch filter plugin [plugins-filters-elasticsearch]


* Plugin version: v4.0.0
* Released on: 2025-01-10
* [Changelog](https://github.com/logstash-plugins/logstash-filter-elasticsearch/blob/v4.0.0/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://docs/reference/filter-elasticsearch-index.md).

## Getting help [_getting_help_138]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-filter-elasticsearch). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_137]

Search Elasticsearch for a previous log event and copy some fields from it into the current event. Below are two complete examples of how this filter might be used.

The first example uses the legacy *query* parameter where the user is limited to an Elasticsearch query_string. Whenever logstash receives an "end" event, it uses this elasticsearch filter to find the matching "start" event based on some operation identifier. Then it copies the `@timestamp` field from the "start" event into a new field on the "end" event.  Finally, using a combination of the "date" filter and the "ruby" filter, we calculate the time duration in hours between the two events.

```ruby
if [type] == "end" {
   elasticsearch {
      hosts => ["es-server"]
      query => "type:start AND operation:%{[opid]}"
      fields => { "@timestamp" => "started" }
   }

   date {
      match => ["[started]", "ISO8601"]
      target => "[started]"
   }

   ruby {
      code => "event.set('duration_hrs', (event.get('@timestamp') - event.get('started')) / 3600)"
   }
}
```

The example below reproduces the above example but utilises the query_template. This query_template represents a full Elasticsearch query DSL and supports the standard Logstash field substitution syntax.  The example below issues the same query as the first example but uses the template shown.

```ruby
if [type] == "end" {
      elasticsearch {
         hosts => ["es-server"]
         query_template => "template.json"
         fields => { "@timestamp" => "started" }
      }

      date {
         match => ["[started]", "ISO8601"]
         target => "[started]"
      }

      ruby {
         code => "event.set('duration_hrs', (event.get('@timestamp') - event.get('started')) / 3600)"
      }
}
```

template.json:

```json
{
  "size": 1,
  "sort" : [ { "@timestamp" : "desc" } ],
  "query": {
    "query_string": {
      "query": "type:start AND operation:%{[opid]}"
    }
  },
  "_source": ["@timestamp"]
}
```

As illustrated above, through the use of *opid*, fields from the Logstash events can be referenced within the template. The template will be populated per event prior to being used to query Elasticsearch.

Notice also that when you use `query_template`, the Logstash attributes `result_size` and `sort` will be ignored. They should be specified directly in the JSON template, as shown in the example above.


## Authentication [plugins-filters-elasticsearch-auth]

Authentication to a secure Elasticsearch cluster is possible using *one* of the following options:

* [`user`](#plugins-filters-elasticsearch-user) AND [`password`](#plugins-filters-elasticsearch-password)
* [`cloud_auth`](#plugins-filters-elasticsearch-cloud_auth)
* [`api_key`](#plugins-filters-elasticsearch-api_key)
* [`ssl_keystore_path`](#plugins-filters-elasticsearch-ssl_keystore_path) and/or [`ssl_keystore_password`](#plugins-filters-elasticsearch-ssl_keystore_password)


## Authorization [plugins-filters-elasticsearch-autz]

Authorization to a secure Elasticsearch cluster requires `read` permission at index level and `monitoring` permissions at cluster level. The `monitoring` permission at cluster level is necessary to perform periodic connectivity checks.


## Elasticsearch Filter Configuration Options [plugins-filters-elasticsearch-options]

This plugin supports the following configuration options plus the [Common options](#plugins-filters-elasticsearch-common-options) described later.

::::{note}
As of version `4.0.0` of this plugin, a number of previously deprecated settings related to SSL have been removed. Please see the [Elasticsearch Filter Obsolete Configuration Options](#plugins-filters-elasticsearch-obsolete-options) for more details.
::::


| Setting | Input type | Required |
| --- | --- | --- |
| [`aggregation_fields`](#plugins-filters-elasticsearch-aggregation_fields) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`api_key`](#plugins-filters-elasticsearch-api_key) | [password](/reference/configuration-file-structure.md#password) | No |
| [`ca_trusted_fingerprint`](#plugins-filters-elasticsearch-ca_trusted_fingerprint) | [string](/reference/configuration-file-structure.md#string) | No |
| [`cloud_auth`](#plugins-filters-elasticsearch-cloud_auth) | [password](/reference/configuration-file-structure.md#password) | No |
| [`cloud_id`](#plugins-filters-elasticsearch-cloud_id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`docinfo_fields`](#plugins-filters-elasticsearch-docinfo_fields) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`enable_sort`](#plugins-filters-elasticsearch-enable_sort) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`fields`](#plugins-filters-elasticsearch-fields) | [array](/reference/configuration-file-structure.md#array) | No |
| [`hosts`](#plugins-filters-elasticsearch-hosts) | [array](/reference/configuration-file-structure.md#array) | No |
| [`index`](#plugins-filters-elasticsearch-index) | [string](/reference/configuration-file-structure.md#string) | No |
| [`password`](#plugins-filters-elasticsearch-password) | [password](/reference/configuration-file-structure.md#password) | No |
| [`proxy`](#plugins-filters-elasticsearch-proxy) | [uri](/reference/configuration-file-structure.md#uri) | No |
| [`query`](#plugins-filters-elasticsearch-query) | [string](/reference/configuration-file-structure.md#string) | No |
| [`query_template`](#plugins-filters-elasticsearch-query_template) | [string](/reference/configuration-file-structure.md#string) | No |
| [`result_size`](#plugins-filters-elasticsearch-result_size) | [number](/reference/configuration-file-structure.md#number) | No |
| [`retry_on_failure`](#plugins-filters-elasticsearch-retry_on_failure) | [number](/reference/configuration-file-structure.md#number) | No |
| [`retry_on_status`](#plugins-filters-elasticsearch-retry_on_status) | [array](/reference/configuration-file-structure.md#array) | No |
| [`sort`](#plugins-filters-elasticsearch-sort) | [string](/reference/configuration-file-structure.md#string) | No |
| [`ssl_certificate`](#plugins-filters-elasticsearch-ssl_certificate) | [path](/reference/configuration-file-structure.md#path) | No |
| [`ssl_certificate_authorities`](#plugins-filters-elasticsearch-ssl_certificate_authorities) | list of [path](/reference/configuration-file-structure.md#path) | No |
| [`ssl_cipher_suites`](#plugins-filters-elasticsearch-ssl_cipher_suites) | list of [string](/reference/configuration-file-structure.md#string) | No |
| [`ssl_enabled`](#plugins-filters-elasticsearch-ssl_enabled) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`ssl_key`](#plugins-filters-elasticsearch-ssl_key) | [path](/reference/configuration-file-structure.md#path) | No |
| [`ssl_keystore_password`](#plugins-filters-elasticsearch-ssl_keystore_password) | [password](/reference/configuration-file-structure.md#password) | No |
| [`ssl_keystore_path`](#plugins-filters-elasticsearch-ssl_keystore_path) | [path](/reference/configuration-file-structure.md#path) | No |
| [`ssl_keystore_type`](#plugins-filters-elasticsearch-ssl_keystore_type) | [string](/reference/configuration-file-structure.md#string) | No |
| [`ssl_supported_protocols`](#plugins-filters-elasticsearch-ssl_supported_protocols) | [string](/reference/configuration-file-structure.md#string) | No |
| [`ssl_truststore_password`](#plugins-filters-elasticsearch-ssl_truststore_password) | [password](/reference/configuration-file-structure.md#password) | No |
| [`ssl_truststore_path`](#plugins-filters-elasticsearch-ssl_truststore_path) | [path](/reference/configuration-file-structure.md#path) | No |
| [`ssl_truststore_type`](#plugins-filters-elasticsearch-ssl_truststore_type) | [string](/reference/configuration-file-structure.md#string) | No |
| [`ssl_verification_mode`](#plugins-filters-elasticsearch-ssl_verification_mode) | [string](/reference/configuration-file-structure.md#string), one of `["full", "none"]` | No |
| [`tag_on_failure`](#plugins-filters-elasticsearch-tag_on_failure) | [array](/reference/configuration-file-structure.md#array) | No |
| [`user`](#plugins-filters-elasticsearch-user) | [string](/reference/configuration-file-structure.md#string) | No |

Also see [Common options](#plugins-filters-elasticsearch-common-options) for a list of options supported by all filter plugins.

 

### `aggregation_fields` [plugins-filters-elasticsearch-aggregation_fields]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

Hash of aggregation names to copy from elasticsearch response into Logstash event fields

Example:

```ruby
    filter {
      elasticsearch {
        aggregation_fields => {
          "my_agg_name" => "my_ls_field"
        }
      }
    }
```


### `api_key` [plugins-filters-elasticsearch-api_key]

* Value type is [password](/reference/configuration-file-structure.md#password)
* There is no default value for this setting.

Authenticate using Elasticsearch API key. Note that this option also requires enabling the [`ssl_enabled`](#plugins-filters-elasticsearch-ssl_enabled) option.

Format is `id:api_key` where `id` and `api_key` are as returned by the Elasticsearch [Create API key API](https://www.elastic.co/docs/api/doc/elasticsearch/operation/operation-security-create-api-key).


### `ca_trusted_fingerprint` [plugins-filters-elasticsearch-ca_trusted_fingerprint]

* Value type is [string](/reference/configuration-file-structure.md#string), and must contain exactly 64 hexadecimal characters.
* There is no default value for this setting.
* Use of this option *requires* Logstash 8.3+

The SHA-256 fingerprint of an SSL Certificate Authority to trust, such as the autogenerated self-signed CA for an Elasticsearch cluster.


### `cloud_auth` [plugins-filters-elasticsearch-cloud_auth]

* Value type is [password](/reference/configuration-file-structure.md#password)
* There is no default value for this setting.

Cloud authentication string ("<username>:<password>" format) is an alternative for the `user`/`password` pair.

For more info, check out the [Logstash-to-Cloud documentation](/reference/connecting-to-cloud.md).


### `cloud_id` [plugins-filters-elasticsearch-cloud_id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Cloud ID, from the Elastic Cloud web console. If set `hosts` should not be used.

For more info, check out the [Logstash-to-Cloud documentation](/reference/connecting-to-cloud.md).


### `docinfo_fields` [plugins-filters-elasticsearch-docinfo_fields]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

Hash of docinfo fields to copy from old event (found via elasticsearch) into new event

Example:

```ruby
    filter {
      elasticsearch {
        docinfo_fields => {
          "_id" => "document_id"
          "_index" => "document_index"
        }
      }
    }
```


### `enable_sort` [plugins-filters-elasticsearch-enable_sort]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Whether results should be sorted or not


### `fields` [plugins-filters-elasticsearch-fields]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `{}`

An array of fields to copy from the old event (found via elasticsearch) into the new event, currently being processed.

In the following example, the values of `@timestamp` and `event_id` on the event found via elasticsearch are copied to the current event’s `started` and `start_id` fields, respectively:

```ruby
fields => {
  "@timestamp" => "started"
  "event_id" => "start_id"
}
```


### `hosts` [plugins-filters-elasticsearch-hosts]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `["localhost:9200"]`

List of elasticsearch hosts to use for querying.


### `index` [plugins-filters-elasticsearch-index]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `""`

Comma-delimited list of index names to search; use `_all` or empty string to perform the operation on all indices. Field substitution (e.g. `index-name-%{{date_field}}`) is available


### `password` [plugins-filters-elasticsearch-password]

* Value type is [password](/reference/configuration-file-structure.md#password)
* There is no default value for this setting.

Basic Auth - password


### `proxy` [plugins-filters-elasticsearch-proxy]

* Value type is [uri](/reference/configuration-file-structure.md#uri)
* There is no default value for this setting.

Set the address of a forward HTTP proxy. An empty string is treated as if proxy was not set, and is useful when using environment variables e.g. `proxy => '${LS_PROXY:}'`.


### `query` [plugins-filters-elasticsearch-query]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Elasticsearch query string. More information is available in the [Elasticsearch query string documentation](elasticsearch://docs/reference/query-languages/query-dsl-query-string-query.md#query-string-syntax). Use either `query` or `query_template`.


### `query_template` [plugins-filters-elasticsearch-query_template]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

File path to elasticsearch query in DSL format. More information is available in the [Elasticsearch query documentation](elasticsearch://docs/reference/query-languages/querydsl.md). Use either `query` or `query_template`.


### `result_size` [plugins-filters-elasticsearch-result_size]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `1`

How many results to return


### `retry_on_failure` [plugins-filters-elasticsearch-retry_on_failure]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `0` (retries disabled)

How many times to retry an individual failed request.

When enabled, retry requests that result in connection errors or an HTTP status code included in [`retry_on_status`](#plugins-filters-elasticsearch-retry_on_status)


### `retry_on_status` [plugins-filters-elasticsearch-retry_on_status]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is an empty list `[]`

Which HTTP Status codes to consider for retries (in addition to connection errors) when using [`retry_on_failure`](#plugins-filters-elasticsearch-retry_on_failure),


### `sort` [plugins-filters-elasticsearch-sort]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"@timestamp:desc"`

Comma-delimited list of `<field>:<direction>` pairs that define the sort order


### `ssl_certificate` [plugins-filters-elasticsearch-ssl_certificate]

* Value type is [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting.

SSL certificate to use to authenticate the client. This certificate should be an OpenSSL-style X.509 certificate file.

::::{note}
This setting can be used only if [`ssl_key`](#plugins-filters-elasticsearch-ssl_key) is set.
::::



### `ssl_certificate_authorities` [plugins-filters-elasticsearch-ssl_certificate_authorities]

* Value type is a list of [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting

The .cer or .pem files to validate the server’s certificate.

::::{note}
You cannot use this setting and [`ssl_truststore_path`](#plugins-filters-elasticsearch-ssl_truststore_path) at the same time.
::::



### `ssl_cipher_suites` [plugins-filters-elasticsearch-ssl_cipher_suites]

* Value type is a list of [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting

The list of cipher suites to use, listed by priorities. Supported cipher suites vary depending on the Java and protocol versions.


### `ssl_enabled` [plugins-filters-elasticsearch-ssl_enabled]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* There is no default value for this setting.

Enable SSL/TLS secured communication to Elasticsearch cluster. Leaving this unspecified will use whatever scheme is specified in the URLs listed in [`hosts`](#plugins-filters-elasticsearch-hosts) or extracted from the [`cloud_id`](#plugins-filters-elasticsearch-cloud_id). If no explicit protocol is specified plain HTTP will be used.


### `ssl_key` [plugins-filters-elasticsearch-ssl_key]

* Value type is [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting.

OpenSSL-style RSA private key that corresponds to the [`ssl_certificate`](#plugins-filters-elasticsearch-ssl_certificate).

::::{note}
This setting can be used only if [`ssl_certificate`](#plugins-filters-elasticsearch-ssl_certificate) is set.
::::



### `ssl_keystore_password` [plugins-filters-elasticsearch-ssl_keystore_password]

* Value type is [password](/reference/configuration-file-structure.md#password)
* There is no default value for this setting.

Set the keystore password


### `ssl_keystore_path` [plugins-filters-elasticsearch-ssl_keystore_path]

* Value type is [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting.

The keystore used to present a certificate to the server. It can be either `.jks` or `.p12`

::::{note}
You cannot use this setting and [`ssl_certificate`](#plugins-filters-elasticsearch-ssl_certificate) at the same time.
::::



### `ssl_keystore_type` [plugins-filters-elasticsearch-ssl_keystore_type]

* Value can be any of: `jks`, `pkcs12`
* If not provided, the value will be inferred from the keystore filename.

The format of the keystore file. It must be either `jks` or `pkcs12`.


### `ssl_supported_protocols` [plugins-filters-elasticsearch-ssl_supported_protocols]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Allowed values are: `'TLSv1.1'`, `'TLSv1.2'`, `'TLSv1.3'`
* Default depends on the JDK being used. With up-to-date Logstash, the default is `['TLSv1.2', 'TLSv1.3']`. `'TLSv1.1'` is not considered secure and is only provided for legacy applications.

List of allowed SSL/TLS versions to use when establishing a connection to the Elasticsearch cluster.

For Java 8 `'TLSv1.3'` is supported only since **8u262** (AdoptOpenJDK), but requires that you set the `LS_JAVA_OPTS="-Djdk.tls.client.protocols=TLSv1.3"` system property in Logstash.

::::{note}
If you configure the plugin to use `'TLSv1.1'` on any recent JVM, such as the one packaged with Logstash, the protocol is disabled by default and needs to be enabled manually by changing `jdk.tls.disabledAlgorithms` in the **$JDK_HOME/conf/security/java.security** configuration file. That is, `TLSv1.1` needs to be removed from the list.
::::



### `ssl_truststore_password` [plugins-filters-elasticsearch-ssl_truststore_password]

* Value type is [password](/reference/configuration-file-structure.md#password)
* There is no default value for this setting.

Set the truststore password


### `ssl_truststore_path` [plugins-filters-elasticsearch-ssl_truststore_path]

* Value type is [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting.

The truststore to validate the server’s certificate. It can be either `.jks` or `.p12`.

::::{note}
You cannot use this setting and [`ssl_certificate_authorities`](#plugins-filters-elasticsearch-ssl_certificate_authorities) at the same time.
::::



### `ssl_truststore_type` [plugins-filters-elasticsearch-ssl_truststore_type]

* Value can be any of: `jks`, `pkcs12`
* If not provided, the value will be inferred from the truststore filename.

The format of the truststore file. It must be either `jks` or `pkcs12`.


### `ssl_verification_mode` [plugins-filters-elasticsearch-ssl_verification_mode]

* Value can be any of: `full`, `none`
* Default value is `full`

Defines how to verify the certificates presented by another party in the TLS connection:

`full` validates that the server certificate has an issue date that’s within the not_before and not_after dates; chains to a trusted Certificate Authority (CA), and has a hostname or IP address that matches the names within the certificate.

`none` performs no certificate validation.

::::{warning}
Setting certificate verification to `none` disables many security benefits of SSL/TLS, which is very dangerous. For more information on disabling certificate verification please read [https://www.cs.utexas.edu/~shmat/shmat_ccs12.pdf](https://www.cs.utexas.edu/~shmat/shmat_ccs12.pdf)
::::



### `tag_on_failure` [plugins-filters-elasticsearch-tag_on_failure]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `["_elasticsearch_lookup_failure"]`

Tags the event on failure to look up previous log event information. This can be used in later analysis.


### `user` [plugins-filters-elasticsearch-user]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Basic Auth - username



## Elasticsearch Filter Obsolete Configuration Options [plugins-filters-elasticsearch-obsolete-options]

::::{warning}
As of version `4.0.0` of this plugin, some configuration options have been replaced. The plugin will fail to start if it contains any of these obsolete options.
::::


| Setting | Replaced by | ca_file |
| --- | --- | --- |
| [`ssl_certificate_authorities`](#plugins-filters-elasticsearch-ssl_certificate_authorities) | keystore | [`ssl_keystore_path`](#plugins-filters-elasticsearch-ssl_keystore_path) |
| keystore_password | [`ssl_keystore_password`](#plugins-filters-elasticsearch-ssl_keystore_password) | ssl |


## Common options [plugins-filters-elasticsearch-common-options]

These configuration options are supported by all filter plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`add_field`](#plugins-filters-elasticsearch-add_field) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`add_tag`](#plugins-filters-elasticsearch-add_tag) | [array](/reference/configuration-file-structure.md#array) | No |
| [`enable_metric`](#plugins-filters-elasticsearch-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-filters-elasticsearch-id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`periodic_flush`](#plugins-filters-elasticsearch-periodic_flush) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`remove_field`](#plugins-filters-elasticsearch-remove_field) | [array](/reference/configuration-file-structure.md#array) | No |
| [`remove_tag`](#plugins-filters-elasticsearch-remove_tag) | [array](/reference/configuration-file-structure.md#array) | No |

### `add_field` [plugins-filters-elasticsearch-add_field]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

If this filter is successful, add any arbitrary fields to this event. Field names can be dynamic and include parts of the event using the `%{{field}}`.

Example:

```json
    filter {
      elasticsearch {
        add_field => { "foo_%{somefield}" => "Hello world, from %{host}" }
      }
    }
```

```json
    # You can also add multiple fields at once:
    filter {
      elasticsearch {
        add_field => {
          "foo_%{somefield}" => "Hello world, from %{host}"
          "new_field" => "new_static_value"
        }
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would add field `foo_hello` if it is present, with the value above and the `%{{host}}` piece replaced with that value from the event. The second example would also add a hardcoded field.


### `add_tag` [plugins-filters-elasticsearch-add_tag]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

If this filter is successful, add arbitrary tags to the event. Tags can be dynamic and include parts of the event using the `%{{field}}` syntax.

Example:

```json
    filter {
      elasticsearch {
        add_tag => [ "foo_%{somefield}" ]
      }
    }
```

```json
    # You can also add multiple tags at once:
    filter {
      elasticsearch {
        add_tag => [ "foo_%{somefield}", "taggedy_tag"]
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would add a tag `foo_hello` (and the second example would of course add a `taggedy_tag` tag).


### `enable_metric` [plugins-filters-elasticsearch-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance. By default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-filters-elasticsearch-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type, for example, if you have 2 elasticsearch filters. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
    filter {
      elasticsearch {
        id => "ABC"
      }
    }
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::



### `periodic_flush` [plugins-filters-elasticsearch-periodic_flush]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Call the filter flush method at regular interval. Optional.


### `remove_field` [plugins-filters-elasticsearch-remove_field]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

If this filter is successful, remove arbitrary fields from this event. Fields names can be dynamic and include parts of the event using the `%{{field}}` Example:

```json
    filter {
      elasticsearch {
        remove_field => [ "foo_%{somefield}" ]
      }
    }
```

```json
    # You can also remove multiple fields at once:
    filter {
      elasticsearch {
        remove_field => [ "foo_%{somefield}", "my_extraneous_field" ]
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would remove the field with name `foo_hello` if it is present. The second example would remove an additional, non-dynamic field.


### `remove_tag` [plugins-filters-elasticsearch-remove_tag]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

If this filter is successful, remove arbitrary tags from the event. Tags can be dynamic and include parts of the event using the `%{{field}}` syntax.

Example:

```json
    filter {
      elasticsearch {
        remove_tag => [ "foo_%{somefield}" ]
      }
    }
```

```json
    # You can also remove multiple tags at once:
    filter {
      elasticsearch {
        remove_tag => [ "foo_%{somefield}", "sad_unwanted_tag"]
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would remove the tag `foo_hello` if it is present. The second example would remove a sad, unwanted tag as well.
