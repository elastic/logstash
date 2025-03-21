---
navigation_title: "Breaking changes"
---

# Logstash breaking changes [logstash-breaking-changes]
Breaking changes can impact your Elastic applications, potentially disrupting normal operations. 
Before you upgrade, carefully review the Logstash breaking changes and take the necessary steps to mitigate any issues. 

% ## Next version [logstash-nextversion-breaking-changes]

% ::::{dropdown} Title of breaking change
% Description of the breaking change.
% For more information, check [PR #](PR link).
% **Impact**<br> Impact of the breaking change.
% **Action**<br> Steps for mitigating deprecation impact.
% ::::

## 9.0.0 [logstash-900-breaking-changes]
**Release date:** April 2, 2025

### Changes to SSL settings in {{ls}} plugins [ssl-settings-9.0]
We’ve removed deprecated SSL settings in some {{ls}} plugins, and have replaced them with updated settings. If your plugin configuration contains any of these obsolete options, the plugin may fail to start.

::::{dropdown} `logstash-input-beats`
:name: input-beats-ssl-9.0

| Setting | Replaced by |
| --- | --- |
| cipher_suites | [`ssl_cipher_suites`](logstash-docs-md://lsr/plugins-inputs-beats.md#plugins-inputs-beats-ssl_cipher_suites) |
| ssl | [`ssl_enabled`](logstash-docs-md://lsr/plugins-inputs-beats.md#plugins-inputs-beats-ssl_enabled) |
| ssl_peer_metadata | `ssl_peer_metadata` option of [`enrich`](logstash-docs-md://lsr/plugins-inputs-beats.md#plugins-inputs-beats-enrich) |
| ssl_verify_mode | [`ssl_client_authentication`](logstash-docs-md://lsr/plugins-inputs-beats.md#plugins-inputs-beats-ssl_client_authentication) |
| tls_min_version | [`ssl_supported_protocols`](logstash-docs-md://lsr/plugins-inputs-beats.md#plugins-inputs-beats-ssl_supported_protocols) |
| tls_max_version | [`ssl_supported_protocols`](logstash-docs-md://lsr/plugins-inputs-beats.md#plugins-inputs-beats-ssl_supported_protocols) |

::::


::::{dropdown} `logstash-input-elastic_agent`
:name: input-elastic_agent-ssl-9.0

| Setting | Replaced by |
| --- | --- |
| cipher_suites | [`ssl_cipher_suites`](logstash-docs-md://lsr/plugins-inputs-elastic_agent.md#plugins-inputs-elastic_agent-ssl_cipher_suites) |
| ssl | [`ssl_enabled`](logstash-docs-md://lsr/plugins-inputs-elastic_agent.md#plugins-inputs-elastic_agent-ssl_enabled) |
| ssl_peer_metadata | `ssl_peer_metadata` option of [`enrich`](logstash-docs-md://lsr/plugins-inputs-elastic_agent.md#plugins-inputs-elastic_agent-enrich) |
| ssl_verify_mode | [`ssl_client_authentication`](logstash-docs-md://lsr/plugins-inputs-elastic_agent.md#plugins-inputs-elastic_agent-ssl_client_authentication) |
| tls_min_version | [`ssl_supported_protocols`](logstash-docs-md://lsr/plugins-inputs-elastic_agent.md#plugins-inputs-elastic_agent-ssl_supported_protocols) |
| tls_max_version | [`ssl_supported_protocols`](logstash-docs-md://lsr/plugins-inputs-elastic_agent.md#plugins-inputs-elastic_agent-ssl_supported_protocols) |

::::


::::{dropdown} `logstash-input-elasticsearch`
:name: input-elasticsearch-ssl-9.0

| Setting | Replaced by |
| --- | --- |
| ca_file | [`ssl_certificate_authorities`](logstash-docs-md://lsr/plugins-inputs-elasticsearch.md#plugins-inputs-elasticsearch-ssl_certificate_authorities) |
| ssl | [`ssl_enabled`](logstash-docs-md://lsr/plugins-inputs-elasticsearch.md#plugins-inputs-elasticsearch-ssl_enabled) |
| ssl_certificate_verification | [`ssl_verification_mode`](logstash-docs-md://lsr/plugins-inputs-elasticsearch.md#plugins-inputs-elasticsearch-ssl_verification_mode) |

::::


::::{dropdown} `logstash-input-elastic_serverless_forwarder`
:name: input-elastic_serverless_forwarder-ssl-9.0

| Setting | Replaced by |
| --- | --- |
| ssl | [`ssl_enabled`](logstash-docs-md://lsr/plugins-inputs-elastic_serverless_forwarder.md#plugins-inputs-elastic_serverless_forwarder-ssl_enabled) |

::::


::::{dropdown} `logstash-input-http`
:name: input-http-ssl-9.0

| Setting | Replaced by |
| --- | --- |
| cipher_suites | [`ssl_cipher_suites`](logstash-docs-md://lsr/plugins-inputs-http.md#plugins-inputs-http-ssl_cipher_suites) |
| keystore | [`ssl_keystore_path`](logstash-docs-md://lsr/plugins-inputs-http.md#plugins-inputs-http-ssl_keystore_path) |
| keystore_password | [`ssl_keystore_password`](logstash-docs-md://lsr/plugins-inputs-http.md#plugins-inputs-http-ssl_keystore_password) |
| ssl | [`ssl_enabled`](logstash-docs-md://lsr/plugins-inputs-http.md#plugins-inputs-http-ssl_enabled) |
| ssl_verify_mode | [`ssl_client_authentication`](logstash-docs-md://lsr/plugins-inputs-http.md#plugins-inputs-http-ssl_client_authentication) |
| tls_max_version | [`ssl_supported_protocols`](logstash-docs-md://lsr/plugins-inputs-http.md#plugins-inputs-http-ssl_supported_protocols) |
| tls_min_version | [`ssl_supported_protocols`](logstash-docs-md://lsr/plugins-inputs-http.md#plugins-inputs-http-ssl_supported_protocols) |
| verify_mode | [`ssl_client_authentication`](logstash-docs-md://lsr/plugins-inputs-http.md#plugins-inputs-http-ssl_client_authentication) |

::::


::::{dropdown} `logstash-input-http_poller`
:name: input-http_poller-ssl-9.0

| Setting | Replaced by |
| --- | --- |
| cacert | [`ssl_certificate_authorities`](logstash-docs-md://lsr/plugins-inputs-http_poller.md#plugins-inputs-http_poller-ssl_certificate_authorities) |
| client_cert | [`ssl_certificate`](logstash-docs-md://lsr/plugins-inputs-http_poller.md#plugins-inputs-http_poller-ssl_certificate) |
| client_key | [`ssl_key`](logstash-docs-md://lsr/plugins-inputs-http_poller.md#plugins-inputs-http_poller-ssl_key) |
| keystore | [`ssl_keystore_path`](logstash-docs-md://lsr/plugins-inputs-http_poller.md#plugins-inputs-http_poller-ssl_keystore_path) |
| keystore_password | [`ssl_keystore_password`](logstash-docs-md://lsr/plugins-inputs-http_poller.md#plugins-inputs-http_poller-ssl_keystore_password) |
| keystore_type | [`ssl_keystore_password`](logstash-docs-md://lsr/plugins-inputs-http_poller.md#plugins-inputs-http_poller-ssl_keystore_password) |
| truststore | [`ssl_truststore_path`](logstash-docs-md://lsr/plugins-inputs-http_poller.md#plugins-inputs-http_poller-ssl_truststore_path) |
| truststore_password | [`ssl_truststore_password`](logstash-docs-md://lsr/plugins-inputs-http_poller.md#plugins-inputs-http_poller-ssl_truststore_password) |
| truststore_type | [`ssl_truststore_type`](logstash-docs-md://lsr/plugins-inputs-http_poller.md#plugins-inputs-http_poller-ssl_truststore_type) |

::::


::::{dropdown} `logstash-input-tcp`
:name: input-tcp-ssl-9.0

| Setting | Replaced by |
| --- | --- |
| ssl_cert | [`ssl_certificate`](logstash-docs-md://lsr/plugins-inputs-tcp.md#plugins-inputs-tcp-ssl_certificate) |
| ssl_enable | [`ssl_enabled`](logstash-docs-md://lsr/plugins-inputs-tcp.md#plugins-inputs-tcp-ssl_enabled) |
| ssl_verify | [`ssl_client_authentication`](logstash-docs-md://lsr/plugins-inputs-tcp.md#plugins-inputs-tcp-ssl_client_authentication) in `server` mode and [`ssl_verification_mode`](logstash-docs-md://lsr/plugins-inputs-tcp.md#plugins-inputs-tcp-ssl_verification_mode) in `client` mode |

::::


::::{dropdown} `logstash-filter-elasticsearch`
:name: filter-elasticsearch-ssl-9.0

| Setting | Replaced by |
| --- | --- |
| ca_file | [`ssl_certificate_authorities`](logstash-docs-md://lsr/plugins-filters-elasticsearch.md#plugins-filters-elasticsearch-ssl_certificate_authorities) |
| keystore | [`ssl_keystore_path`](logstash-docs-md://lsr/plugins-filters-elasticsearch.md#plugins-filters-elasticsearch-ssl_keystore_path) |
| keystore_password | [`ssl_keystore_password`](logstash-docs-md://lsr/plugins-filters-elasticsearch.md#plugins-filters-elasticsearch-ssl_keystore_password) |
| ssl | [`ssl_enabled`](logstash-docs-md://lsr/plugins-filters-elasticsearch.md#plugins-filters-elasticsearch-ssl_enabled) |

::::


::::{dropdown} `logstash-filter-http`
:name: filter-http-ssl-9.0

| Setting | Replaced by |
| --- | --- |
| cacert | [`ssl_certificate_authorities`](logstash-docs-md://lsr/plugins-filters-http.md#plugins-filters-http-ssl_certificate_authorities) |
| client_cert | [`ssl_certificate`](logstash-docs-md://lsr/plugins-filters-http.md#plugins-filters-http-ssl_certificate) |
| client_key | [`ssl_key`](logstash-docs-md://lsr/plugins-filters-http.md#plugins-filters-http-ssl_key) |
| keystore | [`ssl_keystore_path`](logstash-docs-md://lsr/plugins-filters-http.md#plugins-filters-http-ssl_keystore_path) |
| keystore_password | [`ssl_keystore_password`](logstash-docs-md://lsr/plugins-filters-http.md#plugins-filters-http-ssl_keystore_password) |
| keystore_type | [`ssl_keystore_type`](logstash-docs-md://lsr/plugins-filters-http.md#plugins-filters-http-ssl_keystore_type) |
| truststore | [`ssl_truststore_path`](logstash-docs-md://lsr/plugins-filters-http.md#plugins-filters-http-ssl_truststore_path) |
| truststore_password | [`ssl_truststore_password`](logstash-docs-md://lsr/plugins-filters-http.md#plugins-filters-http-ssl_truststore_password) |
| truststore_type | [`ssl_truststore_type`](logstash-docs-md://lsr/plugins-filters-http.md#plugins-filters-http-ssl_truststore_type) |

::::


::::{dropdown} `logstash-output-elasticsearch`
:name: output-elasticsearch-ssl-9.0

| Setting | Replaced by |
| --- | --- |
| cacert | [`ssl_certificate_authorities`](logstash-docs-md://lsr/plugins-outputs-elasticsearch.md#plugins-outputs-elasticsearch-ssl_certificate_authorities) |
| keystore | [`ssl_keystore_path`](logstash-docs-md://lsr/plugins-outputs-elasticsearch.md#plugins-outputs-elasticsearch-ssl_keystore_path) |
| keystore_password | [`ssl_keystore_password`](logstash-docs-md://lsr/plugins-outputs-elasticsearch.md#plugins-outputs-elasticsearch-ssl_keystore_password) |
| ssl | [`ssl_enabled`](logstash-docs-md://lsr/plugins-outputs-elasticsearch.md#plugins-outputs-elasticsearch-ssl_enabled) |
| ssl_certificate_verification | [`ssl_verification_mode`](logstash-docs-md://lsr/plugins-outputs-elasticsearch.md#plugins-outputs-elasticsearch-ssl_verification_mode) |
| truststore | [`ssl_truststore_path`](logstash-docs-md://lsr/plugins-outputs-elasticsearch.md#plugins-outputs-elasticsearch-ssl_truststore_path) |
| truststore_password | [`ssl_truststore_password`](logstash-docs-md://lsr/plugins-outputs-elasticsearch.md#plugins-outputs-elasticsearch-ssl_truststore_password) |

::::


::::{dropdown} `logstash-output-http`
:name: output-http-ssl-9.0

| Setting | Replaced by |
| --- | --- |
| cacert | [`ssl_certificate_authorities`](logstash-docs-md://lsr/plugins-outputs-http.md#plugins-outputs-http-ssl_certificate_authorities) |
| client_cert | [`ssl_certificate`](logstash-docs-md://lsr/plugins-outputs-http.md#plugins-outputs-http-ssl_certificate) |
| client_key | [`ssl_key`](logstash-docs-md://lsr/plugins-outputs-http.md#plugins-outputs-http-ssl_key) |
| keystore | [`ssl_keystore_path`](logstash-docs-md://lsr/plugins-outputs-http.md#plugins-outputs-http-ssl_keystore_path) |
| keystore_password | [`ssl_keystore_password`](logstash-docs-md://lsr/plugins-outputs-http.md#plugins-outputs-http-ssl_keystore_password) |
| keystore_type | [`ssl_keystore_password`](logstash-docs-md://lsr/plugins-outputs-http.md#plugins-outputs-http-ssl_keystore_password) |
| truststore | [`ssl_truststore_path`](logstash-docs-md://lsr/plugins-outputs-http.md#plugins-outputs-http-ssl_truststore_path) |
| truststore_password | [`ssl_truststore_password`](logstash-docs-md://lsr/plugins-outputs-http.md#plugins-outputs-http-ssl_truststore_password) |
| truststore_type | [`ssl_truststore_type`](logstash-docs-md://lsr/plugins-outputs-http.md#plugins-outputs-http-ssl_truststore_type) |

::::


::::{dropdown} `logstash-output-tcp`
:name: output-tcp-ssl-9.0

| Setting | Replaced by |
| --- | --- |
| ssl_cacert | [`ssl_certificate_authorities`](logstash-docs-md://lsr/plugins-outputs-tcp.md#plugins-outputs-tcp-ssl_certificate_authorities) |
| ssl_cert | [`ssl_certificate`](logstash-docs-md://lsr/plugins-outputs-tcp.md#plugins-outputs-tcp-ssl_certificate) |
| ssl_enable | [`ssl_enabled`](logstash-docs-md://lsr/plugins-outputs-tcp.md#plugins-outputs-tcp-ssl_enabled) |
| ssl_verify | [`ssl_client_authentication`](logstash-docs-md://lsr/plugins-outputs-tcp.md#plugins-outputs-tcp-ssl_client_authentication) in `server` mode and [`ssl_verification_mode`](logstash-docs-md://lsr/plugins-outputs-tcp.md#plugins-outputs-tcp-ssl_verification_mode) in `client` mode |

::::


### Pipeline buffer type now `heap` by default [pipeline-buffer-type]

We've introduced a change in `9.0` to improve memory configuration when using certain {{ls}} plugins.
Input plugins such as {agent}, {beats}, TCP, and HTTP allocate buffers in Java memory to read events from the network.
We have changed the default allocation method from `direct` memory to `heap` memory to help simplify configuration, and to help facilitate debugging memory usage problems through the analysis of heap dumps.
To re-enable the previous behavior {{ls}} provides a `pipeline.buffer.type` setting in [logstash.yml](/reference/logstash-settings-file.md) that lets you control where to allocate memory buffers for plugins that use them.
See [off-heap-buffers-allocation](/reference/jvm-settings.md#off-heap-buffers-allocation) for details

For more information, check [#16500](https://github.com/elastic/logstash/pull/16500)

### Removal of {{ls}} modules [removed-modules]

We have removed the modules framework from {{ls}} for 9.0, and we encourage users to use Elastic Integrations
This includes the netflow, azure and arcsight modules, and the modules framework as a whole.

For more information, check [#16514](https://github.com/elastic/logstash/pull/16514) and [#16794](https://github.com/elastic/logstash/pull/16794)


### Removal of deprecated configuration settings [removed-params]

We have removed support for previously deprecated configuration settings:

#### `http.*` prefixed settings for the {{ls}} API
When configuring the {{ls}} API, settings prefixed by `http.*` have been replaced by the equivalent settings prefixed with `api.*`

For information, check [#16552](https://github.com/elastic/logstash/pull/16552)

#### `event_api.tags.illegal`

Any events that include a field named tags will automatically rename that field _tags to avoid any clash
with the reserved {{ls}} tags field. Instead, {{ls}} generates `_tagsparsefailure` in the event `tags` and the illegal value is written to the `_tags` field

For more information, check [#16461](https://github.com/elastic/logstash/pull/16461)


### Ingest converter removed [removed-ingest-converter]

The ingest converter, which was previously used to convert ingest pipelines to {{ls}} pipelines, has been removed.

For more information, check [#16453](https://github.com/elastic/logstash/pull/16453)


### Support for JDK11 dropped [jdk-11-support-drop]

{{ls}} 9.0 will no longer run under JDK11, with JDK17 being the minimum version of the JDK required to run Logstash.
For the best experience, we still recommend running {{ls}} using the bundled-jdk. See [Logstash JVM requirements](/reference/logstash/getting-started-with-logstash.md#[ls-jvm])
for details.

For more information, check [#16443](https://github.com/elastic/logstash/pull/16443)

### Docker base image now UBI9 based [docker-base-image-change]

{{ls}} on Docker, the base image has been changed from Ubuntu to UBI9. If you create a Docker image based on the
{{ls}} image, and rely on it being Ubuntu based, you will need to change your derived image to take account of this
change.

For more information, check [#16599](https://github.com/elastic/logstash/pull/16599)

### Cannot run as `superuser` by default [allow-superuser]

We've changed the default behavior when running {{ls}} to prevent accidentally running {{ls}} as a superuser.
Now if you try and run {{ls}} as a superuser, it will log an error and fail to start, ensuring that you cannot run Logstash
with elevated privileges by accident.
To re-enable the previous behavior, and allow {{ls}} to run with superuser privileges, {{ls}} provides an `allow_superuser`
setting in [logstash.yml](/reference/logstash-settings-file.md)

For more information, check [#16558](https://github.com/elastic/logstash/pull/16558)

### New setting required to continue use of legacy internal monitoring feature [allow-legacy-monitoring]

Starting from 9.0, to continue using the deprecated internal collection method of {{ls}} monitoring, you will need to
set `xpack.monitoring.allow_legacy_collection` to `true` to explicitly permit legacy monitoring.
We encourage you to move to the latest, supported way to monitor Logstash, using agent-driven monitoring.

For more information, check [#16586](https://github.com/elastic/logstash/pull/16586)


### Avoiding JSON log lines collision [avoid-collision-on-json-fields]

We've made a change to how we deal with duplicate `message` fields in `json` documents.
Through certain code paths, when logging in `json`, for example when using the JSON codec, log events can be
produced that include multiple instances of the  `message` field. While this is technically valid JSON, many
clients do not parse this data correctly, and either crash or discard one of the fields. We recently introduced
the option to fix duplicates, and for `9.0` onwards, this will be the default.
To re-enable the previous behavior {{ls}} provides a `log.format.json.fix_duplicate_message_fields` setting in
[logstash.yml](/reference/logstash-settings-file.md).
See [Logging in json format can write duplicate message fields](docs-content://troubleshoot/ingest/logstash.md#logging-in-json-format-can-write-duplicate-message-fields-ts-pipeline-logging-json-duplicated-message-field)
for more details about the issue.

For more information, check [#16578](https://github.com/elastic/logstash/pull/16578)

### Enterprise_search integration plugin is deprecated [enterprise_search-deprecated-9.0]

We’ve deprecated the {{ls}} Enterprise_search integration plugin, and its component App Search and Workplace Search plugins. These plugins will receive only security updates and critical fixes moving forward.

We recommend using our native {{es}} tools for your Search use cases. For more details, please visit the [Search solution and use case documentation](docs-content://solutions/search.md).
