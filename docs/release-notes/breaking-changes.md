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

### Enterprise_search integration plugin is deprecated [enterprise_search-deprecated-9.0]

We’ve deprecated the {{ls}} Enterprise_search integration plugin, and its component App Search and Workplace Search plugins. These plugins will receive only security updates and critical fixes moving forward.

We recommend using our native {{es}} tools for your Search use cases. For more details, please visit the [Search solution and use case documentation](docs-content://solutions/search.md).
