---
navigation_title: "elastic_integration"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-filters-elastic_integration.html
---

# Elastic Integration filter plugin [plugins-filters-elastic_integration]


* Plugin version: v8.17.0
* Released on: 2025-01-08
* [Changelog](https://github.com/elastic/logstash-filter-elastic_integration/blob/v8.17.0/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://docs/reference/filter-elastic_integration-index.md).

## Getting help [_getting_help_137]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-filter-elastic_integration). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).

::::{admonition} Elastic Enterprise License
Use of this plugin requires an active Elastic Enterprise [subscription](https://www.elastic.co/subscriptions).

::::



## Description [_description_136]

Use this filter to process Elastic integrations powered by {{es}} Ingest Node in {{ls}}.

::::{admonition} Extending Elastic integrations with {ls}
This plugin can help you take advantage of the extensive, built-in capabilities of [Elastic {{integrations}}](integration-docs://docs/reference/index.md)—​such as managing data collection, transformation, and visualization—​and then use {{ls}} for additional data processing and output options. For more info about extending Elastic integrations with {{ls}}, check out [Using {{ls}} with Elastic Integrations](/reference/using-logstash-with-elastic-integrations.md).

::::


When you configure this filter to point to an {{es}} cluster, it detects which ingest pipeline (if any) should be executed for each event, using an explicitly-defined [`pipeline_name`](#plugins-filters-elastic_integration-pipeline_name) or auto-detecting the event’s data-stream and its default pipeline.

It then loads that pipeline’s definition from {{es}} and run that pipeline inside Logstash without transmitting the event to {{es}}. Events that are successfully handled by their ingest pipeline will have `[@metadata][target_ingest_pipeline]` set to `_none` so that any downstream {{es}} output in the Logstash pipeline will avoid running the event’s default pipeline *again* in {{es}}.

::::{note}
Some multi-pipeline configurations such as logstash-to-logstash over http(s) do not maintain the state of `[@metadata]` fields. In these setups, you may need to explicitly configure your downstream pipeline’s {{es}} output with `pipeline => "_none"` to avoid re-running the default pipeline.
::::


Events that *fail* ingest pipeline processing will be tagged with `_ingest_pipeline_failure`, and their `[@metadata][_ingest_pipeline_failure]` will be populated with details as a key/value map.

### Requirements and upgrade guidance [plugins-filters-elastic_integration-requirements]

* This plugin requires Java 17 minimum with {{ls}} `8.x` versions and Java 21 minimum with {{ls}} `9.x` versions.
* When you upgrade the {{stack}}, upgrade {{ls}} (or this plugin specifically) *before* you upgrade {{kib}}. (Note that this requirement is a departure from the typical {{stack}} [installation order](docs-content://get-started/installing-elastic-stack.md#install-order-elastic-stack).)

    The {{es}}-{{ls}}-{{kib}} installation order ensures the best experience with {{agent}}-managed pipelines, and embeds functionality from a version of {{es}} Ingest Node that is compatible with the plugin version (`major`.`minor`).



### Using `filter-elastic_integration` with `output-elasticsearch` [plugins-filters-elastic_integration-es-tips]

Elastic {{integrations}} are designed to work with [data streams](/reference/plugins-outputs-elasticsearch.md#plugins-outputs-elasticsearch-data-streams) and [ECS-compatible](/reference/plugins-outputs-elasticsearch.md#_compatibility_with_the_elastic_common_schema_ecs) output. Be sure that these features are enabled in the [`output-elasticsearch`](/reference/plugins-outputs-elasticsearch.md) plugin.

* Set [`data-stream`](/reference/plugins-outputs-elasticsearch.md#plugins-outputs-elasticsearch-data_stream) to `true`.<br> (Check out [Data streams](/reference/plugins-outputs-elasticsearch.md#plugins-outputs-elasticsearch-data-streams) for additional data streams settings.)
* Set [`ecs-compatibility`](/reference/plugins-outputs-elasticsearch.md#plugins-outputs-elasticsearch-ecs_compatibility) to `v1` or `v8`.

Check out the [`output-elasticsearch` plugin](/reference/plugins-outputs-elasticsearch.md) docs for additional settings.



## Minimum configuration [plugins-filters-elastic_integration-minimum_configuration]

You will need to configure this plugin to connect to {{es}}, and may need to also need to provide local GeoIp databases.

```ruby
filter {
  elastic_integration {
    cloud_id   => "YOUR_CLOUD_ID_HERE"
    cloud_auth => "YOUR_CLOUD_AUTH_HERE"
    geoip_database_directory => "/etc/your/geoip-databases"
  }
}
```

Read on for a guide to configuration, or jump to the [complete list of configuration options](#plugins-filters-elastic_integration-options).


## Connecting to {{es}} [plugins-filters-elastic_integration-connecting_to_elasticsearch]

This plugin communicates with {{es}} to identify which ingest pipeline should be run for a given event, and to retrieve the ingest pipeline definitions themselves. You must configure this plugin to point to {{es}} using exactly one of:

* A Cloud Id (see [`cloud_id`](#plugins-filters-elastic_integration-cloud_id))
* A list of one or more host URLs (see [`hosts`](#plugins-filters-elastic_integration-hosts))

Communication will be made securely over SSL unless you explicitly configure this plugin otherwise.

You may need to configure how this plugin establishes trust of the server that responds, and will likely need to configure how this plugin presents its own identity or credentials.

### SSL Trust Configuration [_ssl_trust_configuration]

When communicating over SSL, this plugin fully-validates the proof-of-identity presented by {{es}} using the system trust store. You can provide an *alternate* source of trust with one of:

* A PEM-formatted list of trusted certificate authorities (see [`ssl_certificate_authorities`](#plugins-filters-elastic_integration-ssl_certificate_authorities))
* A JKS- or PKCS12-formatted Keystore containing trusted certificates (see [`ssl_truststore_path`](#plugins-filters-elastic_integration-ssl_truststore_path))

You can also configure which aspects of the proof-of-identity are verified (see [`ssl_verification_mode`](#plugins-filters-elastic_integration-ssl_verification_mode)).


### SSL Identity Configuration [_ssl_identity_configuration]

When communicating over SSL, you can also configure this plugin to present a certificate-based proof-of-identity to the {{es}} cluster it connects to using one of:

* A PKCS8 Certificate/Key pair (see [`ssl_certificate`](#plugins-filters-elastic_integration-ssl_certificate))
* A JKS- or PKCS12-formatted Keystore (see [`ssl_keystore_path`](#plugins-filters-elastic_integration-ssl_keystore_path))


### Request Identity [_request_identity]

You can configure this plugin to present authentication credentials to {{es}} in one of several ways:

* ApiKey: (see [`api_key`](#plugins-filters-elastic_integration-api_key))
* Cloud Auth: (see [`cloud_auth`](#plugins-filters-elastic_integration-cloud_auth))
* HTTP Basic Auth: (see [`username`](#plugins-filters-elastic_integration-username) and [`password`](#plugins-filters-elastic_integration-password))

::::{note}
Your request credentials are only as secure as the connection they are being passed over. They provide neither privacy nor secrecy on their own, and can easily be recovered by an adversary when SSL is disabled.
::::




## Minimum required privileges [plugins-filters-elastic_integration-minimum_required_privileges]

This plugin communicates with Elasticsearch to resolve events into pipeline definitions and needs to be configured with credentials with appropriate privileges to read from the relevant APIs. At the startup phase, this plugin confirms that current user has sufficient privileges, including:

| Privilege name | Description |
| --- | --- |
| `monitor` | A read-only privilege for cluster operations such as cluster health or state. Plugin requires it when checks {{es}} license. |
| `read_pipeline` | A read-only get and simulate access to ingest pipeline. It is required when plugin reads {{es}} ingest pipeline definitions. |
| `manage_index_templates` | All operations on index templates privilege. It is required when plugin resolves default pipeline based on event data stream name. |

::::{note}
This plugin cannot determine if an anonymous user has the required privileges when it connects to an {{es}} cluster that has security features disabled or when the user does not provide credentials. The plugin starts in an unsafe mode with a runtime error indicating that API permissions are insufficient, and prevents events from being processed by the ingest pipeline.

To avoid these issues, set up user authentication and ensure that security in {{es}} is enabled (default).

::::



## Supported Ingest Processors [plugins-filters-elastic_integration-supported_ingest_processors]

This filter can run {{es}} Ingest Node pipelines that are *wholly* comprised of the supported subset of processors. It has access to the Painless and Mustache scripting engines where applicable:

| Source | Processor | Caveats |
| --- | --- | --- |
| Ingest Common | `append` | *none* |
| `bytes` | *none* |
| `communityid` | *none* |
| `convert` | *none* |
| `csv` | *none* |
| `date` | *none* |
| `dateindexname` | *none* |
| `dissect` | *none* |
| `dotexpander` | *none* |
| `drop` | *none* |
| `fail` | *none* |
| `fingerprint` | *none* |
| `foreach` | *none* |
| `grok` | *none* |
| `gsub` | *none* |
| `htmlstrip` | *none* |
| `join` | *none* |
| `json` | *none* |
| `keyvalue` | *none* |
| `lowercase` | *none* |
| `networkdirection` | *none* |
| `pipeline` | resolved pipeline *must* be wholly-composed of supported processors |
| `registereddomain` | *none* |
| `remove` | *none* |
| `rename` | *none* |
| `reroute` | *none* |
| `script` | `lang` must be `painless` (default) |
| `set` | *none* |
| `sort` | *none* |
| `split` | *none* |
| `trim` | *none* |
| `uppercase` | *none* |
| `uri_parts` | *none* |
| `urldecode` | *none* |
| `user_agent` | side-loading a custom regex file is not supported; the processor will use the default user agent definitions as specified in [Elasticsearch processor definition](elasticsearch://docs/reference/ingestion-tools/enrich-processor/user-agent-processor.md) |
| Redact | `redact` | *none* |
| GeoIp | `geoip` | requires MaxMind GeoIP2 databases, which may be provided by Logstash’s Geoip Database Management *OR* configured using [`geoip_database_directory`](#plugins-filters-elastic_integration-geoip_database_directory) |

### Field Mappings [plugins-filters-elastic_integration-field_mappings]

During execution the Ingest pipeline works with a temporary mutable *view* of the Logstash event called an ingest document. This view contains all of the as-structured fields from the event with minimal type conversions.

It also contains additional metadata fields as required by ingest pipeline processors:

* `_version`: a `long`-value integer equivalent to the event’s `@version`, or a sensible default value of `1`.
* `_ingest.timestamp`: a `ZonedDateTime` equivalent to the event’s `@timestamp` field

After execution completes the event is sanitized to ensure that Logstash-reserved fields have the expected shape, providing sensible defaults for any missing required fields. When an ingest pipeline has set a reserved field to a value that cannot be coerced, the value is made available in an alternate location on the event as described below.

| {{ls}} field | type | value |
| --- | --- | --- |
| `@timestamp` | `Timestamp` | First coercible value of the ingest document’s `@timestamp`, `event.created`, `_ingest.timestamp`, or `_now` fields; or the current timestamp.When the ingest document has a value for `@timestamp` that cannot be coerced, it will be available in the event’s `_@timestamp` field. |
| `@version` | String-encoded integer | First coercible value of the ingest document’s `@version`, or `_version` fields; or the current timestamp.When the ingest document has a value for `@version` that cannot be coerced, it will be available in the event’s `_@version` field. |
| `@metadata` | key/value map | The ingest document’s `@metadata`; or an empty map.When the ingest document has a value for `@metadata` that cannot be coerced, it will be available in the event’s `_@metadata` field. |
| `tags` | a String or a list of Strings | The ingest document’s `tags`.When the ingest document has a value for `tags` that cannot be coerced, it will be available in the event’s `_tags` field. |

Additionally, these {{es}} IngestDocument Metadata fields are made available on the resulting event *if-and-only-if* they were set during pipeline execution:

| {{es}} document metadata | {{ls}} field |
| --- | --- |
| `_id` | `[@metadata][_ingest_document][id]` |
| `_index` | `[@metadata][_ingest_document][index]` |
| `_routing` | `[@metadata][_ingest_document][routing]` |
| `_version` | `[@metadata][_ingest_document][version]` |
| `_version_type` | `[@metadata][_ingest_document][version_type]` |
| `_ingest.timestamp` | `[@metadata][_ingest_document][timestamp]` |



## Resolving Pipeline Definitions [plugins-filters-elastic_integration-resolving]

This plugin uses {{es}} to resolve pipeline names into their pipeline definitions. When configured *without* an explicit [`pipeline_name`](#plugins-filters-elastic_integration-pipeline_name), or when a pipeline uses the Reroute Processor, it also uses {{es}} to establish mappings of data stream names to their respective default pipeline names.

It uses hit/miss caches to avoid querying Elasticsearch for every single event. It also works to update these cached mappings *before* they expire. The result is that when {{es}} is responsive this plugin is able to pick up changes quickly without impacting its own performance, and it can survive periods of {{es}} issues without interruption by continuing to use potentially-stale mappings or definitions.

To achieve this, mappings are cached for a maximum of 24 hours, and cached values are reloaded every 1 minute with the following effect:

* when a reloaded mapping is non-empty and is the *same* as its already-cached value, its time-to-live is reset to ensure that subsequent events can continue using the confirmed-unchanged value
* when a reloaded mapping is non-empty and is *different* from its previously-cached value, the entry is *updated* so that subsequent events will use the new value
* when a reloaded mapping is newly *empty*, the previous non-empty mapping is *replaced* with a new empty entry so that subsequent events will use the empty value
* when the reload of a mapping *fails*, this plugin emits a log warning but the existing cache entry is unchanged and gets closer to its expiry.


## Elastic Integration Filter Configuration Options [plugins-filters-elastic_integration-options]

This plugin supports the following configuration options plus the [Common options](#plugins-filters-elastic_integration-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`api_key`](#plugins-filters-elastic_integration-api_key) | [password](/reference/configuration-file-structure.md#password) | No |
| [`cloud_auth`](#plugins-filters-elastic_integration-cloud_auth) | [password](/reference/configuration-file-structure.md#password) | No |
| [`cloud_id`](#plugins-filters-elastic_integration-cloud_id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`geoip_database_directory`](#plugins-filters-elastic_integration-geoip_database_directory) | [path](/reference/configuration-file-structure.md#path) | No |
| [`hosts`](#plugins-filters-elastic_integration-hosts) | [array](/reference/configuration-file-structure.md#array) | No |
| [`password`](#plugins-filters-elastic_integration-password) | [password](/reference/configuration-file-structure.md#password) | No |
| [`pipeline_name`](#plugins-filters-elastic_integration-pipeline_name) | [string](/reference/configuration-file-structure.md#string) | No |
| [`ssl_certificate`](#plugins-filters-elastic_integration-ssl_certificate) | [path](/reference/configuration-file-structure.md#path) | No |
| [`ssl_certificate_authorities`](#plugins-filters-elastic_integration-ssl_certificate_authorities) | [array](/reference/configuration-file-structure.md#array) | No |
| [`ssl_enabled`](#plugins-filters-elastic_integration-ssl_enabled) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`ssl_key`](#plugins-filters-elastic_integration-ssl_key) | [path](/reference/configuration-file-structure.md#path) | No |
| [`ssl_keystore_password`](#plugins-filters-elastic_integration-ssl_keystore_password) | [password](/reference/configuration-file-structure.md#password) | No |
| [`ssl_keystore_path`](#plugins-filters-elastic_integration-ssl_keystore_path) | [path](/reference/configuration-file-structure.md#path) | No |
| [`ssl_key_passphrase`](#plugins-filters-elastic_integration-ssl_key_passphrase) | [password](/reference/configuration-file-structure.md#password) | No |
| [`ssl_truststore_path`](#plugins-filters-elastic_integration-ssl_truststore_path) | [path](/reference/configuration-file-structure.md#path) | No |
| [`ssl_truststore_password`](#plugins-filters-elastic_integration-ssl_truststore_password) | [password](/reference/configuration-file-structure.md#password) | No |
| [`ssl_verification_mode`](#plugins-filters-elastic_integration-ssl_verification_mode) | [string](/reference/configuration-file-structure.md#string), one of `["full", "certificate", "none"]` | No |
| [`username`](#plugins-filters-elastic_integration-username) | [string](/reference/configuration-file-structure.md#string) | No |

### `api_key` [plugins-filters-elastic_integration-api_key]

* Value type is [password](/reference/configuration-file-structure.md#password)
* There is no default value for this setting.

The encoded form of an API key that is used to authenticate this plugin to {{es}}.


### `cloud_auth` [plugins-filters-elastic_integration-cloud_auth]

* Value type is [password](/reference/configuration-file-structure.md#password)
* There is no default value for this setting.

Cloud authentication string ("<username>:<password>" format) is an alternative for the `username`/`password` pair and can be obtained from Elastic Cloud web console.


### `cloud_id` [plugins-filters-elastic_integration-cloud_id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.
* Cannot be combined with `[`ssl_enabled`](#plugins-filters-elastic_integration-ssl_enabled)⇒false`.

Cloud Id, from the Elastic Cloud web console.

When connecting with a Cloud Id, communication to {{es}} is secured with SSL.

For more details, check out the [Logstash-to-Cloud documentation](/reference/connecting-to-cloud.md).


### `geoip_database_directory` [plugins-filters-elastic_integration-geoip_database_directory]

* Value type is [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting.

When running in a Logstash process that has Geoip Database Management enabled, integrations that use the Geoip Processor wil use managed Maxmind databases by default. By using managed databases you accept and agree to the [MaxMind EULA](https://www.maxmind.com/en/geolite2/eula).

You may instead configure this plugin with the path to a local directory containing database files.

This plugin will discover all regular files with the `.mmdb` suffix in the provided directory, and make each available by its file name to the GeoIp processors in integration pipelines. It expects the files it finds to be in the MaxMind DB format with one of the following database types:

* `AnonymousIp`
* `ASN`
* `City`
* `Country`
* `ConnectionType`
* `Domain`
* `Enterprise`
* `Isp`

::::{note}
Most integrations rely on databases being present named *exactly*:

* `GeoLite2-ASN.mmdb`,
* `GeoLite2-City.mmdb`, or
* `GeoLite2-Country.mmdb`

::::



### `hosts` [plugins-filters-elastic_integration-hosts]

* Value type is a list of [uri](/reference/configuration-file-structure.md#uri)s
* There is no default value for this setting.
* Constraints:

    * When any URL contains a protocol component, all URLs must have the same protocol as each other.
    * `https`-protocol hosts use HTTPS and cannot be combined with [`ssl_enabled => false`](#plugins-filters-elastic_integration-ssl_enabled).
    * `http`-protocol hosts use unsecured HTTP and cannot be combined with [`ssl_enabled => true`](#plugins-filters-elastic_integration-ssl_enabled).
    * When any URL omits a port component, the default `9200` is used.
    * When any URL contains a path component, all URLs must have the same path as each other.


A non-empty list of {{es}} hosts to connect.

Examples:

* `"127.0.0.1"`
* `["127.0.0.1:9200","127.0.0.2:9200"]`
* `["http://127.0.0.1"]`
* `["https://127.0.0.1:9200"]`
* `["https://127.0.0.1:9200/subpath"]` (If using a proxy on a subpath)

When connecting with a list of hosts, communication to {{es}} is secured with SSL unless configured otherwise.

::::{admonition} Disabling SSL is dangerous
:class: warning

The security of this plugin relies on SSL to avoid leaking credentials and to avoid running illegitimate ingest pipeline definitions.

There are two ways to disable SSL:

* Provide a list of `http`-protocol hosts
* Set `<<plugins-{{type}}s-{{plugin}}-ssl_enabled>>=>false`

::::



### `password` [plugins-filters-elastic_integration-password]

* Value type is [password](/reference/configuration-file-structure.md#password)
* There is no default value for this setting.
* Required when request auth is configured with [`username`](#plugins-filters-elastic_integration-username)

A password when using HTTP Basic Authentication to connect to {{es}}.


### `pipeline_name` [plugins-filters-elastic_integration-pipeline_name]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.
* When present, the event’s initial pipeline will *not* be auto-detected from the event’s data stream fields.
* Value may be a [sprintf-style](/reference/event-dependent-configuration.md#sprintf) template; if any referenced fields cannot be resolved the event will not be routed to an ingest pipeline.


### `ssl_certificate` [plugins-filters-elastic_integration-ssl_certificate]

* Value type is [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting.
* When present, [`ssl_key`](#plugins-filters-elastic_integration-ssl_key) and [`ssl_key_passphrase`](#plugins-filters-elastic_integration-ssl_key_passphrase) are also required.
* Cannot be combined with configurations that disable SSL

Path to a PEM-encoded certificate or certificate chain with which to identify this plugin to {{es}}.


### `ssl_certificate_authorities` [plugins-filters-elastic_integration-ssl_certificate_authorities]

* Value type is a list of [path](/reference/configuration-file-structure.md#path)s
* There is no default value for this setting.
* Cannot be combined with configurations that disable SSL
* Cannot be combined with `[`ssl_verification_mode`](#plugins-filters-elastic_integration-ssl_verification_mode)⇒none`.

One or more PEM-formatted files defining certificate authorities.

This setting can be used to *override* the system trust store for verifying the SSL certificate presented by {{es}}.


### `ssl_enabled` [plugins-filters-elastic_integration-ssl_enabled]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* There is no default value for this setting.

Secure SSL communication to {{es}} is enabled unless:

* it is explicitly disabled with `ssl_enabled => false`; OR
* it is implicitly disabled by providing `http`-protocol [`hosts`](#plugins-filters-elastic_integration-hosts).

Specifying `ssl_enabled => true` can be a helpful redundant safeguard to ensure this plugin cannot be configured to use non-ssl communication.


### `ssl_key` [plugins-filters-elastic_integration-ssl_key]

* Value type is [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting.
* Required when connection identity is configured with [`ssl_certificate`](#plugins-filters-elastic_integration-ssl_certificate)
* Cannot be combined with configurations that disable SSL

A path to a PKCS8-formatted SSL certificate key.


### `ssl_keystore_password` [plugins-filters-elastic_integration-ssl_keystore_password]

* Value type is [password](/reference/configuration-file-structure.md#password)
* There is no default value for this setting.
* Required when connection identity is configured with [`ssl_keystore_path`](#plugins-filters-elastic_integration-ssl_keystore_path)
* Cannot be combined with configurations that disable SSL

Password for the [`ssl_keystore_path`](#plugins-filters-elastic_integration-ssl_keystore_path).


### `ssl_keystore_path` [plugins-filters-elastic_integration-ssl_keystore_path]

* Value type is [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting.
* When present, [`ssl_keystore_password`](#plugins-filters-elastic_integration-ssl_keystore_password) is also required.
* Cannot be combined with configurations that disable SSL

A path to a JKS- or PKCS12-formatted keystore with which to identify this plugin to {{es}}.


### `ssl_key_passphrase` [plugins-filters-elastic_integration-ssl_key_passphrase]

* Value type is [password](/reference/configuration-file-structure.md#password)
* There is no default value for this setting.
* Required when connection identity is configured with [`ssl_certificate`](#plugins-filters-elastic_integration-ssl_certificate)
* Cannot be combined with configurations that disable SSL

A password or passphrase of the [`ssl_key`](#plugins-filters-elastic_integration-ssl_key).


### `ssl_truststore_path` [plugins-filters-elastic_integration-ssl_truststore_path]

* Value type is [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting.
* When present, [`ssl_truststore_password`](#plugins-filters-elastic_integration-ssl_truststore_password) is required.
* Cannot be combined with configurations that disable SSL
* Cannot be combined with `[`ssl_verification_mode`](#plugins-filters-elastic_integration-ssl_verification_mode)⇒none`.

A path to JKS- or PKCS12-formatted keystore where trusted certificates are located.

This setting can be used to *override* the system trust store for verifying the SSL certificate presented by {{es}}.


### `ssl_truststore_password` [plugins-filters-elastic_integration-ssl_truststore_password]

* Value type is [password](/reference/configuration-file-structure.md#password)
* There is no default value for this setting.
* Required when connection trust is configured with [`ssl_truststore_path`](#plugins-filters-elastic_integration-ssl_truststore_path)
* Cannot be combined with configurations that disable SSL

Password for the [`ssl_truststore_path`](#plugins-filters-elastic_integration-ssl_truststore_path).


### `ssl_verification_mode` [plugins-filters-elastic_integration-ssl_verification_mode]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.
* Cannot be combined with configurations that disable SSL

Level of verification of the certificate provided by {{es}}.

SSL certificates presented by {{es}} are fully-validated by default.

* Available modes:

    * `none`: performs no validation, implicitly trusting any server that this plugin connects to (insecure)
    * `certificate`: validates the server-provided certificate is signed by a trusted certificate authority and that the server can prove possession of its associated private key (less secure)
    * `full` (default): performs the same validations as `certificate` and also verifies that the provided certificate has an identity claim matching the server we are attempting to connect to (most secure)



### `username` [plugins-filters-elastic_integration-username]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.
* When present, [`password`](#plugins-filters-elastic_integration-password) is also required.

A user name when using HTTP Basic Authentication to connect to {{es}}.

 



## Common options [plugins-filters-elastic_integration-common-options]

These configuration options are supported by all filter plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`add_field`](#plugins-filters-elastic_integration-add_field) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`add_tag`](#plugins-filters-elastic_integration-add_tag) | [array](/reference/configuration-file-structure.md#array) | No |
| [`enable_metric`](#plugins-filters-elastic_integration-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-filters-elastic_integration-id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`periodic_flush`](#plugins-filters-elastic_integration-periodic_flush) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`remove_field`](#plugins-filters-elastic_integration-remove_field) | [array](/reference/configuration-file-structure.md#array) | No |
| [`remove_tag`](#plugins-filters-elastic_integration-remove_tag) | [array](/reference/configuration-file-structure.md#array) | No |

### `add_field` [plugins-filters-elastic_integration-add_field]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

If this filter is successful, add any arbitrary fields to this event. Field names can be dynamic and include parts of the event using the `%{{field}}`.

Example:

```json
    filter {
      elastic_integration {
        add_field => { "foo_%{somefield}" => "Hello world, from %{host}" }
      }
    }
```

```json
    # You can also add multiple fields at once:
    filter {
      elastic_integration {
        add_field => {
          "foo_%{somefield}" => "Hello world, from %{host}"
          "new_field" => "new_static_value"
        }
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would add field `foo_hello` if it is present, with the value above and the `%{{host}}` piece replaced with that value from the event. The second example would also add a hardcoded field.


### `add_tag` [plugins-filters-elastic_integration-add_tag]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

If this filter is successful, add arbitrary tags to the event. Tags can be dynamic and include parts of the event using the `%{{field}}` syntax.

Example:

```json
    filter {
      elastic_integration {
        add_tag => [ "foo_%{somefield}" ]
      }
    }
```

```json
    # You can also add multiple tags at once:
    filter {
      elastic_integration {
        add_tag => [ "foo_%{somefield}", "taggedy_tag"]
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would add a tag `foo_hello` (and the second example would of course add a `taggedy_tag` tag).


### `enable_metric` [plugins-filters-elastic_integration-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance. By default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-filters-elastic_integration-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type, for example, if you have 2 elastic_integration filters. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
    filter {
      elastic_integration {
        id => "ABC"
      }
    }
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::



### `periodic_flush` [plugins-filters-elastic_integration-periodic_flush]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Call the filter flush method at regular interval. Optional.


### `remove_field` [plugins-filters-elastic_integration-remove_field]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

If this filter is successful, remove arbitrary fields from this event. Fields names can be dynamic and include parts of the event using the `%{{field}}` Example:

```json
    filter {
      elastic_integration {
        remove_field => [ "foo_%{somefield}" ]
      }
    }
```

```json
    # You can also remove multiple fields at once:
    filter {
      elastic_integration {
        remove_field => [ "foo_%{somefield}", "my_extraneous_field" ]
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would remove the field with name `foo_hello` if it is present. The second example would remove an additional, non-dynamic field.


### `remove_tag` [plugins-filters-elastic_integration-remove_tag]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

If this filter is successful, remove arbitrary tags from the event. Tags can be dynamic and include parts of the event using the `%{{field}}` syntax.

Example:

```json
    filter {
      elastic_integration {
        remove_tag => [ "foo_%{somefield}" ]
      }
    }
```

```json
    # You can also remove multiple tags at once:
    filter {
      elastic_integration {
        remove_tag => [ "foo_%{somefield}", "sad_unwanted_tag"]
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would remove the tag `foo_hello` if it is present. The second example would remove a sad, unwanted tag as well.



