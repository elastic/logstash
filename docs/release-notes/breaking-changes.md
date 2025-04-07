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


:::::{dropdown} Changes to SSL settings in {{ls}} plugins
:name: ssl-deprecations-9.0.0

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
:::::

::::{dropdown} Pipeline buffer type defaults to `heap`
:name: pipeline-buffer-type]

We've improved memory configuration for certain {{ls}} plugins.
Input plugins such as `elastic_agent`, `beats`, `tcp`, and `http` allocate buffers in Java memory to read events from the network.
The default allocation method is `direct` memory rather than `heap` memory to simplify configuration, and to help facilitate debugging memory usage problems through the analysis of heap dumps.
If you need to re-enable the previous behavior, change the `pipeline.buffer.type` setting in [logstash.yml](/reference/logstash-settings-file.md).
Check out [off-heap-buffers-allocation](/reference/jvm-settings.md#off-heap-buffers-allocation) for details. [#16500](https://github.com/elastic/logstash/pull/16500)
::::

::::{dropdown} {{ls}} modules removed 
:name: removed-modules

We have removed the {{ls}} modules framework, and encourage users to try Elastic Integrations
This includes the netflow, azure and arcsight modules, and the modules framework as a whole. [#16794](https://github.com/elastic/logstash/pull/16794)
::::


::::{dropdown} Deprecated configuration settings removed 
:name:removed-params

We have removed support for previously deprecated configuration settings:

- **`http.*` prefixed settings for the {{ls}} API.** Settings prefixed by `http.*` have been replaced by the equivalent settings prefixed with `api.*`. [#16552](https://github.com/elastic/logstash/pull/16552)

- **`event_api.tags.illegal`**
Any events that include field named tags automatically rename the field _tags to avoid any clash
with the reserved {{ls}} tags field. 
Instead, {{ls}} generates `_tagsparsefailure` in the event `tags` and the illegal value is written to the `_tags` field. [#16461](https://github.com/elastic/logstash/pull/16461)
::::

::::{dropdown} Ingest converter removed 
:name: removed-ingest-converter

The ingest converter, which was used to convert ingest pipelines to {{ls}} pipelines, has been removed. [#16453](https://github.com/elastic/logstash/pull/16453)

The `logstash-filter-elastic_integration` plugin offers similar functionality, and can help you use [Logstash to extend Elastic integrations](/reference/using-logstash-with-elastic-integrations.md).
::::

::::{dropdown} JDK11 not supported
:name: jdk-11-support-drop

JDK17 is the minimum version of the JDK required to run Logstash.
For the best experience, we still recommend running {{ls}} using the bundled-jdk. 
See [Logstash JVM requirements](/reference/getting-started-with-logstash.md#ls-jvm)
for details. [#16443](https://github.com/elastic/logstash/pull/16443)
::::

::::{dropdown} Docker base image now UBI9 based
:name: docker-base-image-change

The base image for {{ls}} on Docker has been changed from Ubuntu to UBI9.
If you create a Docker image based on the {{ls}} image and rely on it being Ubuntu based, you need to change your derived image to take account of this change. 
For example, if your derived docker image installs additional packages using a package manager, UBI9 uses `microdnf`, rather than `apt`.
[#16599](https://github.com/elastic/logstash/pull/16599)
::::

::::{dropdown} Cannot run {{ls}} as `superuser` by default
:name: [disallow-superuser

We've changed the default behavior to prevent users from accidentally running {{ls}} as a superuser.
If you try to run {{ls}} as a superuser, it logs an error and fails to start, ensuring that users cannot run Logstash with elevated privileges by accident.

You can change the value of the `allow_superuser` setting to `true` in [logstash.yml](/reference/logstash-settings-file.md) if you want to restore the previous behavior and allow {{ls}} to run with superuser privileges. [#16558](https://github.com/elastic/logstash/pull/16558)
::::

::::{dropdown} New setting required to continue using legacy internal monitoring
:name: allow-legacy-monitoring

To continue using deprecated internal collection to monitor {{ls}}, set `xpack.monitoring.allow_legacy_collection` to `true` in [logstash.yml](/reference/logstash-settings-file.md).
We encourage you to move to [agent-driven monitoring](/reference/monitoring-logstash-with-elastic-agent.md), the latest, supported way to monitor Logstash [#16586](https://github.com/elastic/logstash/pull/16586)
::::

::::{dropdown} Avoiding JSON log lines collision
:name: avoid-collision-on-json-fields

We've improved the way we deal with duplicate `message` fields in `json` documents.
Some code paths that log in `json` produce log events that include multiple instances of the  `message` field. (The JSON codec plugin is one example.)
While this approach produces JSON that is technically valid, many clients do not parse this data correctly, and either crash or discard one of the fields.

We recently introduced the option to fix duplicates, and made it the default behavior for `9.0` and later.
To re-enable the previous behavior, change the `log.format.json.fix_duplicate_message_fields` setting in [logstash.yml](/reference/logstash-settings-file.md) to `false`.

Check out [Logging in json format can write duplicate message fields](docs-content://troubleshoot/ingest/logstash.md) for more details about the issue. [#16578](https://github.com/elastic/logstash/pull/16578)
::::

::::{dropdown} Enterprise_search integration plugin is removed from default Logstash install
:name: enterprise_search-deprecated-9.0

We’ve removed the {{ls}} Enterprise_search integration plugin, and its component App Search and Workplace Search plugins from the default {{ls}} install. 
These plugins will receive only security updates and critical fixes moving forward.

We recommend using our native {{es}} tools for your Search use cases. For more details, please visit the [Search solution and use case documentation](docs-content://solutions/search.md).
::::

