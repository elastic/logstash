---
navigation_title: "FIPS 140-2/3 plugin compatibility"
applies_to:
  stack: ga
---

# FIPS 140-2/3 plugin compatibility [fips-plugin-compatibility]

This page documents the FIPS 140-2/3 compatibility status of every Logstash plugin in the [logstash-plugins](https://github.com/logstash-plugins) GitHub organization. Plugins are grouped into three categories:

- **Works out of the box (OOTB)**: No configuration changes needed when FIPS mode is enabled.
- **Works with restrictions**: Plugin works in FIPS mode but has limitations, non-FIPS defaults, or requires specific configuration.
- **Not compatible**: Plugin cannot be used in FIPS mode, uses a cryptographically non-FIPS protocol that cannot be changed, or hardcodes TLS certificate verification off with no way to enable it.

Plugins marked **SKIP** have no published source code (stub/placeholder repositories) and cannot be audited.

## How Logstash runs FIPS

Logstash runs BouncyCastle FIPS in **C:HYBRID mode**, matching Elasticsearch's FIPS configuration. In hybrid mode, the BCFIPS provider is the first registered JVM security provider and handles all security-sensitive operations (TLS, key derivation, signature verification) using FIPS-validated algorithms. Non-security uses of non-approved algorithms (such as MD5 for internal filename generation or deduplication keys) are permitted but do not carry FIPS validation.

When `fips_mode.enabled: true` is set in `logstash.yml`, Logstash additionally:

1. Calls `SecurityHelper.setSecurityProvider(BCFIPSProvider)` before any `require "openssl"`, routing all JCE operations (ciphers, digests, key factories, MACs, etc.) through the BouncyCastle FIPS provider.
2. Sets `-Djruby.openssl.ssl.provider=BCJSSE` so that `SSLContext` operations use the BCJSSE TLS provider.
3. Sets `-Djruby.openssl.provider.register=false` so that the BouncyCastle 1.84 jar bundled with jruby-openssl is loaded as a class library but not registered as a JCE provider.

This means any plugin that uses Ruby `OpenSSL::` APIs for TLS will automatically use FIPS-approved algorithms. The issues documented below are cases where a plugin uses a weak algorithm for a **security purpose** (authentication, encryption, integrity verification of network data), hardcodes TLS certificate verification off, or does not accept BCFKS keystores.

### Ruby filter and user-supplied code

`logstash-filter-ruby` allows arbitrary Ruby code execution. Because the jruby-openssl routing patch is in effect for the entire process, any `OpenSSL::` call made inside a Ruby filter script — including `OpenSSL::Digest`, `OpenSSL::Cipher`, and `OpenSSL::SSL` — automatically uses the BCFIPS/BCJSSE providers. There is nothing special about the filter itself; it inherits the same FIPS-routed crypto environment as the rest of Logstash.

Under C:HYBRID mode, a Ruby filter that calls `Digest::MD5.hexdigest(value)` works — MD5 for a non-security purpose is permitted. A Ruby filter that calls `OpenSSL::Cipher.new("DES-CBC")` also works at the Ruby level in C:HYBRID, but DES is not a FIPS-approved algorithm and using it for encryption is a security operation. **The compliance responsibility for the content of Ruby filter scripts belongs to the operator**, not to Logstash. FIPS compliance requires that the operator not configure non-FIPS cryptography in their pipeline scripts.

Logstash does not disable `logstash-filter-ruby` in FIPS mode. The jruby-openssl routing ensures that the underlying JCE/JSSE plumbing is FIPS-validated; what the operator does with it is subject to their own FIPS boundary controls.

## BCFKS keystore support

FIPS mode requires BCFKS (BouncyCastle FIPS KeyStore) format for JVM keystores. Plugins that expose `ssl_keystore_type` or `ssl_truststore_type` validators must include `bcfks` as a valid value. Where noted in the tables below, this has been added to bundled plugins. The `logstash-mixin-http_client` shared library also needs this fix (see [Mixins](#mixins)).

For plugins that use PEM-based SSL configuration (`ssl_certificate`, `ssl_key`, `ssl_certificate_authorities`), no keystore format changes are needed.

---

## Bundled plugins

These plugins ship with every Logstash distribution.

### Works out of the box (bundled)

| Plugin | Notes |
|--------|-------|
| logstash-input-beats | Netty TLS; uses JVM providers |
| logstash-input-elasticsearch | TLS via Manticore; uses JVM providers |
| logstash-input-http | Netty TLS |
| logstash-input-http_poller | TLS via Manticore |
| logstash-input-jdbc | No crypto; delegates to JDBC driver |
| logstash-input-kafka | Kafka client TLS uses JVM providers |
| logstash-input-redis | No TLS |
| logstash-input-stdin | No crypto |
| logstash-input-syslog | No crypto |
| logstash-input-tcp | TLS via jruby-openssl → BCFIPS |
| logstash-input-udp | No crypto |
| logstash-output-elasticsearch | TLS via Manticore; uses JVM providers |
| logstash-output-http | TLS via Manticore |
| logstash-output-kafka | Kafka client TLS uses JVM providers |
| logstash-output-redis | No TLS in bundled version |
| logstash-output-stdout | No crypto |
| logstash-output-tcp | TLS via jruby-openssl → BCFIPS |
| logstash-filter-clone | No crypto |
| logstash-filter-csv | No crypto |
| logstash-filter-dissect | No crypto |
| logstash-filter-dns | No crypto |
| logstash-filter-drop | No crypto |
| logstash-filter-elasticsearch | TLS via Faraday; uses JVM providers |
| logstash-filter-geoip | No crypto |
| logstash-filter-grok | No crypto |
| logstash-filter-http | TLS via Manticore |
| logstash-filter-json | No crypto |
| logstash-filter-kv | No crypto |
| logstash-filter-memcached | No crypto |
| logstash-filter-mutate | No crypto |
| logstash-filter-ruby | jruby-openssl is routed through BCFIPS/BCJSSE for the whole process, so all `OpenSSL::` calls inside Ruby filter scripts automatically use FIPS-validated providers. Compliance responsibility for script content belongs to the operator. See [Ruby filter and user-supplied code](#ruby-filter-and-user-supplied-code). |
| logstash-filter-sleep | No crypto |
| logstash-filter-split | No crypto |
| logstash-filter-translate | No crypto |
| logstash-filter-truncate | No crypto |
| logstash-filter-xml | No crypto |
| logstash-codec-avro | `bcfks` added to `ssl_keystore_type`/`ssl_truststore_type` validators |
| logstash-codec-cef | No crypto |
| logstash-codec-json | No crypto |
| logstash-codec-json_lines | No crypto |
| logstash-codec-line | No crypto |
| logstash-codec-multiline | No crypto |
| logstash-codec-netflow | No crypto in plugin layer |
| logstash-codec-plain | No crypto |

### Works with restrictions (bundled)

| Plugin | Restriction | Action required |
|--------|-------------|-----------------|
| logstash-codec-avro | TLS via Manticore/jruby-openssl (BCFIPS-routed). `bcfks` is now a valid keystore/truststore type. | Use `ssl_keystore_type => "bcfks"` when pointing to a BCFKS keystore. |
| logstash-filter-elastic_integration | `ssl_keystore_path` and `ssl_truststore_path` are blocked in FIPS mode. The underlying Java layer (`KeyStoreUtil`) cannot resolve BCFKS keystores. Logstash raises `ConfigurationError` at startup if these settings are used with FIPS enabled. | Use `ssl_certificate` + `ssl_key` for client auth, and `ssl_certificate_authorities` for server trust. |
| logstash-filter-date | No crypto; but be aware that `timezone` fields and locale handling do not involve any cryptographic operations. | No action needed. |
| logstash-filter-fingerprint | Default algorithm is `SHA1` (not FIPS-approved). Will fail at runtime under FIPS approved-only mode. | Set `algorithm => "SHA256"` (or SHA384/SHA512). Do not use `MD5` or `SHA1`. |
| logstash-filter-useragent | No crypto. | No action needed. |
| logstash-filter-uuid | Uses `SecureRandom.uuid` (FIPS-safe). | No action needed. |
| logstash-integration-aws | AWS SDK is FIPS-compliant, but standard AWS endpoints are not FIPS-validated. | Set `use_fips_endpoint: true` on all AWS integration plugins (s3, sqs, sns, cloudwatch, etc.). |
| logstash-integration-elasticsearch | ES output: no `truststore_type`/`keystore_type` config exists so BCFKS cannot be explicitly declared. ES filter and input have no cert-verification control. | Use PEM-based SSL options (`ca_file`, `ssl_certificate`, `ssl_key`) rather than keystores. |
| logstash-integration-kafka | SCRAM-SHA-1 SASL mechanism is not FIPS-approved. | Use `SCRAM-SHA-256` or `SCRAM-SHA-512` if SASL/SCRAM authentication is required. |
| logstash-integration-jdbc | No crypto in plugin layer; JDBC driver handles TLS. | Ensure your JDBC driver is FIPS-validated. |
| logstash-integration-rabbitmq | Inherits `logstash-mixin-rabbitmq_connection` issues: TLS certificate verification is **off by default** when no `ssl_certificate_path` is provided; `ssl_version` accepts any string including `TLSv1.1`. | Always set `ssl_certificate_path` (forces peer verification). Explicitly set `ssl_version => "TLSv1.2"` or `"TLSv1.3"`. |
| logstash-integration-snmp | Exposes `auth_protocol` (allows `md5`) and `priv_protocol` (allows `des`, `3des`). | Set `auth_protocol` to `sha`, `sha2`, or higher. Set `priv_protocol` to `aes`, `aes128`, `aes192`, or `aes256`. Do not use `md5`, `des`, or `3des`. |

---

## Additional plugins

These plugins are available from the [logstash-plugins](https://github.com/logstash-plugins) GitHub organization but are not bundled with the default Logstash distribution. Install them with `bin/logstash-plugin install <plugin-name>`.

### Works out of the box (additional)

| Plugin | Notes |
|--------|-------|
| logstash-input-cloudwatch | AWS SDK; no plugin-level crypto |
| logstash-input-couchdb_changes | HTTPS via Manticore |
| logstash-input-dead_letter_queue | No crypto |
| logstash-input-drupal_dblog | Plain MySQL; no crypto |
| logstash-input-elastic_serverless_forwarder | SSL well-structured; defaults to cert verification on |
| logstash-input-eventlog | Windows Event Log; no crypto |
| logstash-input-exec | Process execution; no crypto |
| logstash-input-file | No crypto (sincedb MD5 issue is in `build_random_sincedb_filename` in the standalone plugin, not this bundled version — see restrictions) |
| logstash-input-ganglia | UDP; no crypto |
| logstash-input-gelf | TCP/UDP; no crypto |
| logstash-input-gemfire | GemFire Java client; SSL via JVM config |
| logstash-input-generator | Synthetic events; no crypto |
| logstash-input-google_cloud_storage | GCP SDK handles TLS; no plugin-level SSL bypass |
| logstash-input-google_pubsub | GCP SDK handles TLS |
| logstash-input-graphite | TCP; no crypto |
| logstash-input-heartbeat | No crypto |
| logstash-input-jmx | JMX; SSL at JVM level |
| logstash-input-journald | No crypto (`Base64.encode64` for binary fields only) |
| logstash-input-kinesis | AWS KCL; SDK handles TLS |
| logstash-input-lumberjack | TLS via jruby-openssl → BCFIPS |
| logstash-input-meetup | Faraday HTTPS; no explicit SSL bypass |
| logstash-input-neo4j | No crypto |
| logstash-input-perfmon | Windows Performance Monitor; no crypto |
| logstash-input-pipe | No crypto |
| logstash-input-rabbitmq | TLS via Bunny gem using jruby-openssl → BCFIPS |
| logstash-input-rackspace | Fog gem HTTPS; no explicit bypass |
| logstash-input-relp | TLS via jruby-openssl → BCFIPS; PEM-based SSL only |
| logstash-input-rss | Faraday HTTPS; no explicit SSL bypass |
| logstash-input-s3 (integration-aws version) | AWS SDK handles TLS; use this version, not standalone |
| logstash-input-s3sqs | AWS SDK handles TLS |
| logstash-input-salesforce | Restforce gem HTTPS; no explicit bypass |
| logstash-input-snmp (integration version) | Same restriction as integration-snmp above — use FIPS-approved protocols |
| logstash-input-sqlite | No crypto |
| logstash-input-sqs | `md5_field` stores an SQS-provided MD5 string (not a Ruby `Digest::MD5` call); no FIPS violation |
| logstash-input-stomp | Plain STOMP; no crypto |
| logstash-input-tcp | TLS via jruby-openssl → BCFIPS |
| logstash-input-twitter | HTTPS via jruby-openssl → BCFIPS |
| logstash-input-unix | Unix domain sockets; no crypto |
| logstash-input-varnishlog | Varnish shared memory; no crypto |
| logstash-input-wmi | Windows WMI; no crypto |
| logstash-input-xmpp | xmpp4r gem handles TLS; no explicit bypass in plugin |
| logstash-input-zenoss | RabbitMQ; no direct crypto |
| logstash-input-zeromq | ZMQ framing only; no CURVE/ZAP auth in plugin |
| logstash-output-appsearch | Delegates to app-search gem; no explicit SSL config |
| logstash-output-csv | File write; no crypto |
| logstash-output-elastic_app_search | Delegates to elastic-app-search gem; no explicit SSL config |
| logstash-output-email | TLS via jruby-openssl → BCFIPS |
| logstash-output-exec | Shell exec; no crypto |
| logstash-output-file | File write; no crypto |
| logstash-output-ganglia | UDP; no crypto |
| logstash-output-gelf | UDP/TCP; no crypto |
| logstash-output-gemfire | GemFire Java client; SSL at JVM level |
| logstash-output-google_bigquery | Google SDK handles TLS |
| logstash-output-google_cloud_storage | Google SDK handles TLS |
| logstash-output-google_pubsub | Google SDK handles TLS |
| logstash-output-graphite | Plain TCP; no crypto |
| logstash-output-graphtastic | UDP/TCP/HTTP; no SSL bypass |
| logstash-output-hipchat | hipchat gem; no explicit bypass |
| logstash-output-irc | Cinch gem SSL; no explicit bypass |
| logstash-output-jira | jira-ruby gem HTTPS; no explicit bypass |
| logstash-output-jms | JMS/JNDI; SSL at JVM/broker level |
| logstash-output-juggernaut | Redis-backed; no TLS |
| logstash-output-lumberjack | TLS via lumberjack gem → jruby-openssl → BCFIPS |
| logstash-output-metriccatcher | UDP; no crypto |
| logstash-output-mongodb | TLS via mongoid; JVM providers |
| logstash-output-nagios | Nagios command file; no crypto |
| logstash-output-nagios_nsca | Shells to `send_nsca`; encryption in NSCA config |
| logstash-output-neo4j | Embedded Neo4j; no network SSL |
| logstash-output-null | No-op; no crypto |
| logstash-output-opentsdb | Plain TCP; no crypto |
| logstash-output-pipe | Subprocess; no crypto |
| logstash-output-rackspace | Fog gem HTTPS; no explicit bypass |
| logstash-output-rabbitmq | TLS via Bunny gem → jruby-openssl → BCFIPS |
| logstash-output-riak | riak gem; no explicit VERIFY_NONE |
| logstash-output-riemann | TCP/UDP via riemann-client; no TLS |
| logstash-output-s3 | AWS SDK handles TLS |
| logstash-output-slack | rest-client gem honours OpenSSL defaults; no bypass |
| logstash-output-sns | AWS SDK handles TLS |
| logstash-output-solr_http | rsolr gem; no explicit bypass |
| logstash-output-sqs | AWS SDK handles TLS |
| logstash-output-statsd | UDP; no crypto |
| logstash-output-stomp | onstomp gem; no explicit bypass |
| logstash-output-udp | Raw UDP; no crypto |
| logstash-output-webhdfs | webhdfs gem; cert/key via PEM, no VERIFY_NONE |
| logstash-output-websocket | WSS via jruby-openssl → BCFIPS |
| logstash-output-xmpp | xmpp4r gem; no explicit bypass |
| logstash-output-zabbix | No SSL/crypto |
| logstash-output-zeromq | ZMQ framing only; no CURVE auth |
| logstash-output-zookeeper | zk gem; no explicit bypass |
| logstash-filter-aggregate | No crypto |
| logstash-filter-alter | No crypto |
| logstash-filter-cidr | No crypto |
| logstash-filter-collate | No crypto |
| logstash-filter-de_dot | No crypto |
| logstash-filter-elapsed | No crypto |
| logstash-filter-environment | No crypto |
| logstash-filter-extractnumbers | No crypto |
| logstash-filter-i18n | No crypto |
| logstash-filter-jdbc_static | No crypto in plugin layer |
| logstash-filter-jdbc_streaming | No crypto in plugin layer |
| logstash-filter-json_encode | No crypto |
| logstash-filter-kubernetes_metadata | `verify_api_ssl: false` is user-controlled, not hardcoded |
| logstash-filter-language | No crypto |
| logstash-filter-math | No crypto |
| logstash-filter-metricize | No crypto |
| logstash-filter-metrics | Uses `SecureRandom.hex` (FIPS-safe) |
| logstash-filter-multiline | No crypto |
| logstash-filter-oui | No crypto |
| logstash-filter-prune | No crypto |
| logstash-filter-punct | No crypto |
| logstash-filter-range | No crypto |
| logstash-filter-syslog_pri | No crypto |
| logstash-filter-throttle | No crypto |
| logstash-filter-tld | No crypto |
| logstash-filter-unique | No crypto |
| logstash-filter-urldecode | No crypto |
| logstash-filter-uuid | Uses `SecureRandom.uuid` (FIPS-safe) |
| logstash-filter-yaml | No crypto |
| logstash-filter-zeromq | No crypto |
| logstash-filter-age | No crypto |
| logstash-filter-bytes | No crypto |
| logstash-filter-emoji | No crypto |
| logstash-codec-cloudfront | Gzip decompression only; no crypto |
| logstash-codec-cloudtrail | No crypto |
| logstash-codec-compress_spooler | zlib + MessagePack; no crypto |
| logstash-codec-csv | No crypto |
| logstash-codec-dots | No crypto |
| logstash-codec-edn | No crypto |
| logstash-codec-edn_lines | No crypto |
| logstash-codec-es_bulk | No crypto |
| logstash-codec-fluent | No crypto |
| logstash-codec-graphite | No crypto |
| logstash-codec-gzip_lines | No crypto |
| logstash-codec-msgpack | No crypto |
| logstash-codec-nmap | No crypto |
| logstash-codec-oldlogstashjson | No crypto |
| logstash-codec-pretty | No crypto |
| logstash-codec-protobuf | No crypto |
| logstash-codec-rubydebug | No crypto |
| logstash-codec-s3plain | No crypto |

### Works with restrictions (additional)

| Plugin | Restriction | Action required |
|--------|-------------|-----------------|
| logstash-input-file (standalone) | Uses `Digest::MD5` to generate a sincedb filename from the watch path. This is a **non-security** use (internal filename generation from operator-supplied config); it works under C:HYBRID mode. SHA256 is still recommended for future-proofing. | Works as-is. Optionally patch to use `Digest::SHA256` for sincedb filename. |
| logstash-input-imap | Uses `Digest::MD5` to generate a sincedb filename from IMAP connection parameters. **Non-security** use; works under C:HYBRID. | Works as-is. Optionally patch to use `Digest::SHA256`. |
| logstash-input-irc | SSL delegated to Cinch gem with no cipher or verification controls exposed at plugin level. | Verify Cinch gem's SSL behavior separately. Prefer inputs with explicit SSL configuration for FIPS deployments. |
| logstash-input-puppet_facter | Hardcodes `http.verify_mode = OpenSSL::SSL::VERIFY_NONE` in its SSL path. Certificate validation is completely disabled. | Do not use this plugin in FIPS mode until the upstream code is fixed to default to `VERIFY_PEER`. |
| logstash-input-s3 (standalone) | Uses `Digest::MD5` for sincedb filename generation. **Non-security** use; works under C:HYBRID. | Works as-is. Alternatively use the `logstash-integration-aws` version which does not use MD5. |
| logstash-input-snmp (standalone) | `auth_protocol` allows `md5` and `priv_protocol` allows `des`/`3des`. These are **security operations** (SNMPv3 message authentication and payload encryption). Using them is not FIPS-compliant even in C:HYBRID mode. | Do not configure `auth_protocol: md5`, `priv_protocol: des`, or `priv_protocol: 3des`. Use `auth_protocol: sha`/`sha2` or higher. Use `priv_protocol: aes`/`aes128`/`aes192`/`aes256`. |
| logstash-filter-checksum | Allows `MD5` and `SHA1` algorithm values. These are used for **internal event deduplication** (non-security use) and work under C:HYBRID. SHA256 is recommended. | Use `SHA256` or higher for best practice. `MD5`/`SHA1` work at runtime but are not FIPS-validated operations. |
| logstash-filter-cipher | No algorithm FIPS guard. Non-FIPS ciphers (`DES`, `RC4`, `CAMELLIA`, `BLOWFISH`) perform **security operations** (encryption/decryption) and are not FIPS-compliant. | Restrict `algorithm` to FIPS-approved ciphers: `AES-128-CBC`, `AES-256-CBC`, `AES-128-GCM`, `AES-256-GCM`. |
| logstash-filter-fingerprint | Default algorithm is `SHA1`. Used for **event deduplication ID generation** (non-security use); works under C:HYBRID. SHA256 is strongly recommended. | Set `algorithm => "SHA256"` (or SHA384/SHA512/MURMUR3/MURMUR3_128) for best practice. |
| logstash-filter-hashid | Default algorithm is `MD5`. Uses HMAC for **Elasticsearch document ID generation** (non-security use); works under C:HYBRID. SHA256 is strongly recommended. | Set `algorithm => "SHA256"` (or SHA384/SHA512). Note: changing the algorithm changes hash output values, which breaks downstream lookups keyed on existing hashid values. |
| logstash-output-boundary | Hardcodes `verify_mode = OpenSSL::SSL::VERIFY_NONE`. | Do not use in FIPS mode. |
| logstash-output-circonus | Hardcodes `verify_mode = OpenSSL::SSL::VERIFY_NONE`. | Do not use in FIPS mode. |
| logstash-output-datadog | Hardcodes `verify_mode = OpenSSL::SSL::VERIFY_NONE`. | Do not use in FIPS mode. |
| logstash-output-datadog_metrics | Hardcodes `verify_mode = OpenSSL::SSL::VERIFY_NONE`. | Do not use in FIPS mode. |
| logstash-output-icinga | `ssl_verify: false` sets `VERIFY_NONE`; default is `true` (safe). | Keep `ssl_verify: true` (default). |
| logstash-output-influxdb | `verify_ssl: false` is hardcoded. Certificate validation is unconditionally disabled. | Do not use in FIPS mode. |
| logstash-output-librato | Hardcodes `verify_mode = OpenSSL::SSL::VERIFY_NONE`. | Do not use in FIPS mode. |
| logstash-output-loggly | Hardcodes `verify_mode = OpenSSL::SSL::VERIFY_NONE` when using HTTPS. | Do not use in FIPS mode. |
| logstash-output-monasca_log_api | `*_insecure: true` sets `VERIFY_NONE`; defaults to `false` (safe). | Keep `monasca_log_api_insecure: false` and `keystone_api_insecure: false` (defaults). |
| logstash-output-newrelic | Hardcodes `verify_mode = OpenSSL::SSL::VERIFY_NONE`. | Do not use in FIPS mode. |
| logstash-output-pagerduty | Hardcodes `verify_mode = OpenSSL::SSL::VERIFY_NONE`. | Do not use in FIPS mode. |
| logstash-output-redmine | Hardcodes `verify_mode = OpenSSL::SSL::VERIFY_NONE` whenever `ssl: true`. | Do not use in FIPS mode. |
| logstash-output-redis (standalone) | `ssl_verification_mode: none` is a valid value; `ssl_supported_protocols` includes `TLSv1.1`. | Set `ssl_verification_mode: full` (default). Do not set `ssl_supported_protocols: ["TLSv1.1"]`. |
| logstash-output-syslog | `ssl_verify` defaults to `false`, effectively using `VERIFY_NONE` when SSL is enabled. | Explicitly set `ssl_verify: true` when using `ssl-tcp` protocol. |
| logstash-output-timber | `keystore_type` and `truststore_type` default to `"JKS"` (not FIPS-valid). | Set `keystore_type: "BCFKS"` and `truststore_type: "BCFKS"` when pointing to BCFKS keystores. |

### Not compatible (additional)

| Plugin | Reason | Severity |
|--------|--------|----------|
| logstash-codec-collectd | The `security_level => "Encrypt"` mode mandates SHA-1 for post-decryption **integrity verification** of network packets and AES-256-OFB for **payload decryption** — both are security operations not approved under FIPS 140-3. These algorithms are dictated by the collectd wire format and cannot be changed. The `security_level => "Sign"` mode (SHA-256 HMAC) is FIPS-ok and can be used. | High — do not use `security_level => "Encrypt"` in FIPS mode; `"Sign"` and `"None"` are safe |
| logstash-filter-anonymize | Uses `OpenSSL::HMAC` with MD5 or SHA1 to pseudonymize field values using a secret key. This is a **security operation** — the key-based HMAC is the mechanism that prevents reversal of anonymization. HMAC-MD5 and HMAC-SHA1 are not FIPS-approved for security use even in C:HYBRID mode. This plugin is deprecated. | High — do not use in FIPS mode; use `logstash-filter-fingerprint` with `algorithm => "SHA256"` instead |
| logstash-input-github | GitHub webhook signature verification uses HMAC-SHA1 (`X-Hub-Signature` header). Verifying a **network message's authenticity** using HMAC-SHA1 is a security operation. This is protocol-mandated by GitHub and cannot be changed. | High — do not use in FIPS mode |
| logstash-input-snmptrap | The plugin itself contains no hash crypto (SNMPv1/v2c uses cleartext community strings, not MD5). However, SNMPv1/v2c community strings are transmitted in cleartext with no authentication — this is incompatible with FIPS in-transit security requirements for sensitive data. | Medium — acceptable only if the SNMP traffic is within a secured network boundary |
| logstash-integration-zeromq | ZeroMQ has no TLS transport layer. The CURVE encryption option uses Curve25519/NaCl, which is not on the FIPS 140-2 approved algorithm list. Any cross-host use is incompatible with FIPS in-transit encryption requirements. | High — do not use across host boundaries in FIPS mode |
| logstash-output-boundary | Hardcodes `VERIFY_NONE` with no override. | High — do not use in FIPS mode |
| logstash-output-circonus | Hardcodes `VERIFY_NONE` with no override. | High — do not use in FIPS mode |
| logstash-output-datadog | Hardcodes `VERIFY_NONE` with no override. | High — do not use in FIPS mode |
| logstash-output-datadog_metrics | Hardcodes `VERIFY_NONE` with no override. | High — do not use in FIPS mode |
| logstash-output-influxdb | `verify_ssl: false` is hardcoded. No override possible. | High — do not use in FIPS mode |
| logstash-output-librato | Hardcodes `VERIFY_NONE` with no override. | High — do not use in FIPS mode |
| logstash-output-loggly | Hardcodes `VERIFY_NONE` on HTTPS with no override. | High — do not use in FIPS mode |
| logstash-output-newrelic | Hardcodes `VERIFY_NONE` with no override. | High — do not use in FIPS mode |
| logstash-output-pagerduty | Hardcodes `VERIFY_NONE` with no override. | High — do not use in FIPS mode |
| logstash-output-redmine | Hardcodes `VERIFY_NONE` whenever SSL is enabled. | High — do not use in FIPS mode |

### Stub repositories (no source code to audit)

The following repositories exist in the logstash-plugins organization but contain no Ruby source code. They cannot be audited and should not be installed:

`logstash-input-cloudwatch_logs`, `logstash-input-drupal_dblog`, `logstash-input-elastic_agent`, `logstash-input-fluentd`, `logstash-input-googleanalytics`, `logstash-input-jmx-pipe`, `logstash-input-log4j2`, `logstash-input-mongodb`, `logstash-input-netflow`, `logstash-output-beats`, `logstash-output-firehose`, `logstash-output-logentries`, `logstash-output-rados`, `logstash-filter-bytesize`, `logstash-filter-cloudfoundry`, `logstash-filter-debug`, `logstash-filter-lookup`, `logstash-filter-script`, `logstash-codec-json_pretty`, `logstash-codec-sflow`, `logstash-integration-azure`

---

## Mixin libraries [mixins]

Mixin libraries are shared modules included by many plugins. Issues here have wide blast radius.

| Mixin | Status | Finding |
|-------|--------|---------|
| logstash-mixin-aws | OOTB | No Ruby crypto; delegates to AWS SDK (SigV4/HMAC-SHA256, FIPS-approved). Plugins must be configured to use FIPS endpoint URLs. |
| logstash-mixin-http_client | NEEDS WORK | `ssl_keystore_type` and `ssl_truststore_type` validators only accept `pkcs12` and `jks` — `bcfks` is rejected. Affects every plugin that includes this mixin: `logstash-input-http_poller`, `logstash-output-http`, `logstash-output-logstash`, and others. Also accepts `TLSv1.1` in `ssl_supported_protocols`. |
| logstash-mixin-rabbitmq_connection | NEEDS WORK | TLS certificate verification is off by default when no `ssl_certificate_path` is provided. `ssl_version` accepts any string (including `TLSv1.1`). No BCFKS truststore support. |

---

## Summary counts

| Category | Count |
|----------|-------|
| Works out of the box | ~140 |
| Works with restrictions | ~30 |
| Not compatible | ~14 |
| Stub/no source | ~21 |
| **Total audited** | **~205** |

The "not compatible" count is dominated by older output plugins (boundary, circonus, datadog, librato, loggly, newrelic, pagerduty, redmine) that were written before FIPS was a concern and hardcode `VERIFY_NONE`. All bundled plugins either work out of the box or work with documented configuration restrictions.
