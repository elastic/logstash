---
navigation_title: "Logstash"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/releasenotes.html
  - https://www.elastic.co/guide/en/logstash/master/upgrading-logstash-9.0.html
---

# Logstash release notes [logstash-release-notes]

Review the changes, fixes, and more in each version of Logstash.

To check for security updates, go to [Security announcements for the Elastic stack](https://discuss.elastic.co/c/announcements/security-announcements/31).

% Release notes include only features, enhancements, and fixes. Add breaking changes, deprecations, and known issues to the applicable release notes sections.

% ## version.next [logstash-next-release-notes]

% ### Features and enhancements [logstash-next-features-enhancements]
% *

% ### Fixes [logstash-next-fixes]
% *

## 9.3.1 [logstash-9.3.1-release-notes]

### Features and enhancements [logstash-9.3.1-features-enhancements]

---------- GENERATED CONTENT STARTS HERE ------------
=== Logstash Pull Requests with label v9.3.1

=== Logstash Commits between 9.3 and 9.3.0

Computed with "git log --pretty=format:'%h -%d %s (%cr) <%an>' --abbrev-commit --date=relative v9.3.0..9.3"

75f5ddd69 - (HEAD -> 9.3, origin/9.3) Test rpm and deb packages on aarch64 in exhaustive test pipeline (#18780) (#18795) (14 hours ago) <mergify[bot]>
96486d97b - Doc: Update svrless docs to use endpoint url (#18773) (#18792) (15 hours ago) <mergify[bot]>
c2fc2fc39 - Update patch plugin versions in gemfile lock (#18777) (2 days ago) <github-actions[bot]>
a6c72c15e - Avoid duplicate steps in snyk artifact scanning (#18768) (#18776) (3 days ago) <mergify[bot]>
2ac816929 - [CI] Sync acceptance test OS matrix with JDK matrix pipeline (#18739) (#18744) (2 weeks ago) <mergify[bot]>
dba7890b2 - Respect ARCH env var when downloading JDK via gradle (#18733) (#18750) (2 weeks ago) <mergify[bot]>
708ab1e6d - Add known issues running 9.2.5 on aarch64 architectures (#18731) (#18735) (2 weeks ago) <Rob Bavey>
56ce4f9f7 - [9.3] (backport #18678) Release notes for 9.2.5 (#18719) (2 weeks ago) <mergify[bot]>
0de54db9d - Add known issues about aarch64 to release notes (#18730) (2 weeks ago) <Rob Bavey>
4cb510990 - Clarify input param to bump LS version GHA (#18715) (#18727) (2 weeks ago) <mergify[bot]>
1b736db2b - [DOCS] Update API docs branch detail (#18710) (2 weeks ago) <Lisa Cawley>
5702bd040 - Add Debian 13 to linux matrix (#18698) (#18718) (2 weeks ago) <mergify[bot]>
c468fe751 - [9.3] (backport #18557) Add Snyk scanning for Logstash release artifacts (#18689) (2 weeks ago) <mergify[bot]>
1fad026a2 - Change the default logger level for licensereader (#18644) (#18654) (2 weeks ago) <mergify[bot]>
c3c38ac64 - Bump logstash version 9.3.1 (#18524) (2 weeks ago) <github-actions[bot]>
c9131eebf - 9.3.0 release notes copied from #18581 (#18703) (3 weeks ago) <Mashhur>
18d0e2dc7 - Fix obserbabilitySRE DRA jobs after docker update on runners (#18699) (#18702) (3 weeks ago) <mergify[bot]>
a9f841df0 - Ensure jruby managed with gradle bootstrap is used everywher in CI (#18676) (#18686) (3 weeks ago) <mergify[bot]>
daea190f2 - Fix smart exhaustive test pipeline (#18661) (#18683) (3 weeks ago) <mergify[bot]>
1e3831e8f - Bump requests in /.buildkite/scripts/health-report-tests (#17702) (#18674) (3 weeks ago) <mergify[bot]>
c17b0ab81 - Only raise PR to bump java version when all artifacts are ready (#18668) (#18671) (3 weeks ago) <mergify[bot]>
b592905eb - Dont persist bundler config state across ci tasks (#18655) (#18658) (4 weeks ago) <mergify[bot]>
d84e13377 - [9.3] (backport #18615) Consistent bundled jruby across all CI tasks (#18642) (4 weeks ago) <mergify[bot]>
0fb187ea5 - Use gradle and bundled jruby for acceptance tests orchestration (#18536) (#18634) (4 weeks ago) <mergify[bot]>
d7438aabe - test artifact upgrade from 8.19 instead of 7.17 (#18635) (#18637) (4 weeks ago) <mergify[bot]>
229179200 - Fix ironbank container build (#18625) (#18629) (4 weeks ago) <mergify[bot]>
1004ec721 - Add Ironbank acceptance tests to CI (#18585) (#18623) (4 weeks ago) <mergify[bot]>

=== Logstash Plugin Release Changelogs ===
Computed from "git diff v9.3.0..9.3 *.release"
Changed plugin versions:
logstash-codec-collectd: 3.1.0 -> 3.1.1
logstash-codec-netflow: 4.3.3 -> 4.3.4
logstash-filter-date: 3.1.15 -> 3.1.16
logstash-filter-dissect: 1.2.5 -> 1.2.6
logstash-filter-geoip: 7.3.2 -> 7.3.4
logstash-filter-grok: 4.4.3 -> 4.4.4
logstash-input-beats: 7.0.5 -> 7.0.7
logstash-input-dead_letter_queue: 2.0.1 -> 2.0.2
logstash-input-file: 4.4.6 -> 4.4.7
logstash-input-http: 4.1.4 -> 4.1.6
logstash-input-tcp: 7.0.4 -> 7.0.6
logstash-input-unix: 3.1.2 -> 3.1.3
logstash-integration-jdbc: 5.6.1 -> 5.6.3
logstash-integration-kafka: 11.8.2 -> 11.8.3
logstash-integration-snmp: 4.2.1 -> 4.2.2
logstash-output-elasticsearch: 12.1.1 -> 12.1.2
logstash-output-nagios: 3.0.6 -> 3.0.7
logstash-output-webhdfs: 3.1.0 -> 3.1.1
---------- GENERATED CONTENT ENDS HERE ------------

### Plugins [logstash-plugin-9.3.1-changes]

**Collectd Codec - 3.1.1**

* Fix: replace deprecated `File.exists?` with `File.exist?` for Ruby 3.4 (JRuby 10) compatibility [#36](https://github.com/logstash-plugins/logstash-codec-collectd/pull/36)

**Netflow Codec - 4.3.4**

* Fix: replace deprecated `File.exists?` with `File.exist?` for Ruby 3.4 (JRuby 10) compatibility [#215](https://github.com/logstash-plugins/logstash-codec-netflow/pull/215)

**Date Filter - 3.1.16**

* Re-packaging the plugin [#163](https://github.com/logstash-plugins/logstash-filter-date/pull/163)

**Dissect Filter - 1.2.6**

* Re-packaging the plugin [#93](https://github.com/logstash-plugins/logstash-filter-dissect/pull/93)
* Removed `jar-dependencies` dependency [#91](https://github.com/logstash-plugins/logstash-filter-dissect/pull/91)
  

**Geoip Filter - 7.3.4**

* Fix: replace deprecated `File.exists?` with `File.exist?` for Ruby 3.4 (JRuby 10) compatibility [#239](https://github.com/logstash-plugins/logstash-filter-geoip/pull/239)

* Re-packaging the plugin [#236](https://github.com/logstash-plugins/logstash-filter-geoip/pull/236)

**Grok Filter - 4.4.4**

* Fix: replace deprecated `File.exists?` with `File.exist?` for Ruby 3.4 (JRuby 10) compatibility [#197](https://github.com/logstash-plugins/logstash-filter-grok/pull/197)

**Beats Input - 7.0.7**

* Upgrade netty 4.1.131 [#531](https://github.com/logstash-plugins/logstash-input-beats/pull/531)

* Re-packaging the plugin [#527](https://github.com/logstash-plugins/logstash-input-beats/pull/527)

**Dead_letter_queue Input - 2.0.2**

* Re-packaging the plugin [#57](https://github.com/logstash-plugins/logstash-input-dead_letter_queue/pull/57)

**File Input - 4.4.7**

* Re-packaging the plugin [#331](https://github.com/logstash-plugins/logstash-input-file/pull/331)

**Http Input - 4.1.6**

* Upgrade netty to 4.1.131 [#207](https://github.com/logstash-plugins/logstash-input-http/pull/207)

* Re-packaging the plugin [#206](https://github.com/logstash-plugins/logstash-input-http/pull/206)

**Tcp Input - 7.0.6**

* Upgrade netty to 4.1.131 [#246](https://github.com/logstash-plugins/logstash-input-tcp/pull/246)

* Re-packaging the plugin [#242](https://github.com/logstash-plugins/logstash-input-tcp/pull/242)

**Unix Input - 3.1.3**

* Fix: replace deprecated `File.exists?` with `File.exist?` for Ruby 3.4 (JRuby 10) compatibility [#31](https://github.com/logstash-plugins/logstash-input-unix/pull/31)

**Jdbc Integration - 5.6.3**

* Fix: replace deprecated `File.exists?` with `File.exist?` for Ruby 3.4 (JRuby 10) compatibility [#192](https://github.com/logstash-plugins/logstash-integration-jdbc/pull/192)

* Re-packaging the plugin [#190](https://github.com/logstash-plugins/logstash-integration-jdbc/pull/190)

**Kafka Integration - 11.8.3**

* Re-packaging the plugin [#223](https://github.com/logstash-plugins/logstash-integration-kafka/pull/223)

**Snmp Integration - 4.2.2**

* Re-packaging the plugin [#86](https://github.com/logstash-plugins/logstash-integration-snmp/pull/86)

**Elasticsearch Output - 12.1.2**

* Fix: replace deprecated `File.exists?` with `File.exist?` for Ruby 3.4 (JRuby 10) compatibility [#1238](https://github.com/logstash-plugins/logstash-output-elasticsearch/pull/1238)

**Nagios Output - 3.0.7**

* Fix: replace deprecated `File.exists?` with `File.exist?` for Ruby 3.4 (JRuby 10) compatibility [#11](https://github.com/logstash-plugins/logstash-output-nagios/pull/11)

**Webhdfs Output - 3.1.1**

* Re-packaging the plugin [#49](https://github.com/logstash-plugins/logstash-output-webhdfs/pull/49)


## 9.3.0 [logstash-9.3.0-release-notes]

::::{important}

Do not upgrade to Logstash 9.3.0 if you are running on `aarch64` with the bundled JDK and are not using Docker.
For more details please see the associated [known issue](/release-notes/known-issues.md#logstash-ki-9.3.0).

::::


### Features and enhancements [logstash-9.3.0-features-enhancements]

#### Wait for status feature added to Logstash API [logstash-9.3.0-wait-status]
We've added additional `wait_for_status` and `timeout` query parameters to the Logstash root endpoint `/`. When calling the endpoint with these parameters set, the call will return when either the Logstash status matches (or improves on) the given status, or the given timeout has expired.

Related:
* Add `wait_for_status` and `timeout` query params for `_health_report` API [#18377](https://github.com/elastic/logstash/pull/18377)
#### Additional features and enhancements [logstash-9.3.0-more-features]

* Expose average batch metrics at 1, 5 and 15 minutes time window [#18460](https://github.com/elastic/logstash/pull/18460)

### Fixes [logstash-9.3.0-fixes]

* Fix an issue with Central Management where a spurious 404 when looking up pipeline definitions could cause the running pipelines to shut down [#18265](https://github.com/elastic/logstash/pull/18265)

### Plugins [logstash-plugin-9.3.0-changes]

**Avro Codec - 3.5.0**

* Standardize SSL configurations, add proxy and basic auth supports [#47](https://github.com/logstash-plugins/logstash-codec-avro/pull/47)
    * Add SSL/TLS support for HTTPS schema registry connections
    * Add `ssl_enabled` option to enable/disable SSL
    * Add `ssl_certificate` and `ssl_key` options for PEM-based client authentication (unencrypted keys only)
    * Add `ssl_certificate_authorities` option for PEM-based server certificate validation
    * Add `ssl_verification_mode` option to control SSL verification (full, none)
    * Add `ssl_cipher_suites` option to configure cipher suites
    * Add `ssl_supported_protocols` option to configure TLS protocol versions (TLSv1.1, TLSv1.2, TLSv1.3)
    * Add `ssl_truststore_path` and `ssl_truststore_password` options for server certificate validation (JKS/PKCS12)
    * Add `ssl_keystore_path` and `ssl_keystore_password` options for mutual TLS authentication (JKS/PKCS12)
    * Add `ssl_truststore_type` and `ssl_keystore_type` options (JKS or PKCS12)
    * Add HTTP proxy support with `proxy` option
    * Add HTTP basic authentication support with `username` and `password` options

**Netflow Codec - 4.3.3**

* Fix `NoMethodError` when decode fails [#214](https://github.com/logstash-plugins/logstash-codec-netflow/pull/214)

**Cidr Filter - 3.2.0**

* Feature: Add `address_field` config option to handle nested fields [#29](https://github.com/logstash-plugins/logstash-filter-cidr/pull/29)

**Elastic_integration Filter - 9.3.0**

* Embeds Ingest Node components from Elasticsearch 9.3 [#378](https://github.com/elastic/logstash-filter-elastic_integration/pull/378)

**Azure_event_hubs Input - 1.5.4**

* Ensure full jar-dependency tree is shipped with gem artifact [#110](https://github.com/logstash-plugins/logstash-input-azure_event_hubs/pull/110)
* Remove unused `adal4j` dependency [#107](https://github.com/logstash-plugins/logstash-input-azure_event_hubs/pull/107)

**Kafka Integration - 11.8.2**

* Upgrade transitive `org.apache.commons:commons-lang3` dependency [#217](https://github.com/logstash-plugins/logstash-integration-kafka/pull/217)

**Snmp Integration - 4.2.1**

* Upgrade log4j dependency [#85](https://github.com/logstash-plugins/logstash-integration-snmp/pull/85)

* Add AES256 with 3DES extension support for `priv_protocol` [#78](https://github.com/logstash-plugins/logstash-integration-snmp/pull/78)

**Elasticsearch Output - 12.1.1**

* Remove duplicated deprecation log entry [#1232](https://github.com/logstash-plugins/logstash-output-elasticsearch/pull/1232)

* Add `drop_error_types` config option to avoid retrying on certain error types [#1228](https://github.com/logstash-plugins/logstash-output-elasticsearch/pull/1228)


## 9.2.5 [logstash-9.2.5-release-notes]


::::{important}

Do not upgrade to Logstash 9.2.5 if you need to run Logstash on `aarch64` architectures using the bundled JDK, and are
not running on Docker.
For more details please see the associated [known issue](/release-notes/known-issues.md#logstash-ki-9.2.5).

::::

### Features and enhancements [logstash-9.2.5-features-enhancements]

No user-facing changes in Logstash core.

### Plugins [logstash-plugin-9.2.5-changes]

**Netflow Codec - 4.3.3**

* Made decoding more robust to malformed events [#214](https://github.com/logstash-plugins/logstash-codec-netflow/pull/214)

**Azure_event_hubs Input - 1.5.4**

* Ensure gem artifact ship with all runtime dependencies [#110](https://github.com/logstash-plugins/logstash-input-azure_event_hubs/pull/110)
* Remove unused Azure Active Directory dependency [#107](https://github.com/logstash-plugins/logstash-input-azure_event_hubs/pull/107)

**Kafka Integration - 11.8.2**

* Upgrade transitive dependency used by Avro serializer [#217](https://github.com/logstash-plugins/logstash-integration-kafka/pull/217)


## 9.2.4 [logstash-9.2.4-release-notes]

### Features and enhancements [logstash-9.2.4-features-enhancements]

* Fix to clean batch statistic metrics on pipeline shutdown [#18515](https://github.com/elastic/logstash/pull/18515)

### Plugins [logstash-plugin-9.2.4-changes]

::::{Deprecations to Kafka partitioner settings}
The Kafka integration plugin version bundled with this release introduces deprecations for `partitioner` settings in the Kafka output. Check out [Deprecations](/release-notes/deprecations.md) for more information.
::::

**Beats Input - 7.0.5**

* Upgrade netty 4.1.129 [#525](https://github.com/logstash-plugins/logstash-input-beats/pull/525)

**Http Input - 4.1.4**

* Upgrade netty to 4.1.129 [#203](https://github.com/logstash-plugins/logstash-input-http/pull/203)

**Tcp Input - 7.0.4**

* Upgrade netty to 4.1.129 [#239](https://github.com/logstash-plugins/logstash-input-tcp/pull/239)

**Kafka Integration - 11.8.1**

* Upgrade lz4 dependency [#213](https://github.com/logstash-plugins/logstash-integration-kafka/pull/213)
* Deprecate partitioner `default` and `uniform_sticky` options [#206](https://github.com/logstash-plugins/logstash-integration-kafka/pull/206)
      Both options are deprecated in Kafka client 3 and will be removed in the plugin 12.0.0.
* Add `reconnect_backoff_max_ms` option for configuring kafka client [#204](https://github.com/logstash-plugins/logstash-integration-kafka/pull/204)


## 9.2.3 [logstash-9.2.3-release-notes]

### Features and enhancements [logstash-9.2.3-features-enhancements]

Updated logging in JSON format to include pipeline and plugin IDs. [#18470](https://github.com/elastic/logstash/pull/18470)

### Plugins [logstash-plugin-9.2.3-changes]

No user-facing changes in Logstash plugins.


## 9.2.2 [logstash-9.2.2-release-notes]

No user-facing changes in Logstash core.

### Plugins [logstash-plugin-9.2.2-changes]

**Split Filter - 3.1.10**

* Added trace log to track event size expansion [#49](https://github.com/logstash-plugins/logstash-filter-split/pull/49)
* [DOC] Added introductory statement to clarify purpose of the plugin [#43](https://github.com/logstash-plugins/logstash-filter-split/pull/43)

## 9.2.1 [logstash-9.2.1-release-notes]

### Features and enhancements [logstash-9.2.1-features-enhancements]

* Fix Logstash startup failure when `queue.max_bytes` exceeds 2 GiB [#18366](https://github.com/elastic/logstash/pull/18366)

* Deprecation logs are now written to both the deprecation logger and the standard logger [#18326](https://github.com/elastic/logstash/pull/18326)


### Updates to dependencies [logstash-9.2.1-dependencies]

* Update JDK to 21.0.9 [#18350](https://github.com/elastic/logstash/pull/18350)

### Plugins [logstash-plugin-9.2.1-changes]

**Geoip Filter - 7.3.2**

* Add logs when MaxMind databases fail to deserialize custom field [#235](https://github.com/logstash-plugins/logstash-filter-geoip/pull/235)

**Mutate Filter - 3.5.9**

* Fix `convert` to correctly parse hexadecimal float notation and scientific notation strings into floats and integers [#175](https://github.com/logstash-plugins/logstash-filter-mutate/pull/175)

**Azure_event_hubs Input - 1.5.3**

* Fix an issue when `config_mode => 'advanced'` is set, event hub-specific settings (`initial_position`, `max_batch_size`, `prefetch_count`, `receive_timeout`, `initial_position_look_back`) were being ignored and replaced with global defaults. These settings are now correctly applied per event hub [#104](https://github.com/logstash-plugins/logstash-input-azure_event_hubs/pull/104)

**Rabbitmq Integration - 7.4.1**

* Improve thread safety to avoid race conditions during shutdown [#67](https://github.com/logstash-plugins/logstash-integration-rabbitmq/pull/66)

## 9.2.0 [logstash-9.2.0-release-notes]

::::{important}

Do not upgrade to Logstash 9.2.0 if you use the Persistent Queue (PQ) with a value of `queue.max_bytes` greater than 2GiB, 
For more details please see the associated [known issue](/release-notes/known-issues.md#logstash-ki-9.2.0).
::::

### Features and enhancements [logstash-9.2.0-features-enhancements]

#### Persistent queue (PQ) compression [logstash-9.2.0-pq-compression]

We’ve added support for compression to the [Persistent Queue (PQ)](https://www.elastic.co/docs/reference/logstash/persistent-queues), allowing you to spend some CPU in exchange for reduced disk IO. This can help reduce cost and increase throughput in situations where your hardware is rate-limited or metered.

PQ compression is implemented using the industry-standard highly-efficient ZSTD algorithm, and can be activated at one of three levels:

* Speed: spend the least amount of CPU to get minimal compression benefit
* Balanced: spend moderate CPU to further reduce size
* Size: enable maximum compression, at significantly higher cost

The effects of these settings will depend on the shape and size of each pipeline’s events. To help you tune your configuration to meet your own requirements, we have added [queue metrics](https://www.elastic.co/docs/api/doc/logstash/operation/operation-nodestatspipelines) exposing the effective compression ratio and the amount of CPU that is being spent to achieve it.

PQ Compression has been introduced as an opt-in feature in 9.2 because a PQ that contains one or more compressed events cannot be read by previous versions of Logstash, making the feature a rollback-barrier. We recommend validating your pipelines with Logstash 9.2 (or later) before enabling PQ compression so that you have the freedom to roll back if you encounter any issues with your pipelines.

Related:
* Persisted Queue: improved serialization to be more compact by default (note: queues containing these compact events can be processed by Logstash v8.10.0 and later) [#17849](https://github.com/elastic/logstash/pull/17849)
* Support for user defined metrics [#18218](https://github.com/elastic/logstash/pull/18218)
* PQ: Add support for event-level compression using ZStandard (ZSTD) [#18121](https://github.com/elastic/logstash/pull/18121)

#### Batch size metrics [logstash-9.2.0-batch-size-metrics]

We've added metrics to help you track the size of batches processed by Logstash pipelines. 

The [Node API pipelines endpoint](https://www.elastic.co/docs/api/doc/logstash/operation/operation-nodestatspipelines) now shows includes information displaying the showing the average number of events processed per batch, and the average byte size of those batches for each pipeline. This information can be used to help size Logstash instances, and optimize settings for `pipeline.batch.size` for Logstash pipelines based on real observations of data.

Related:
* Implements current batch event count and byte size metrics [#18160](https://github.com/elastic/logstash/pull/18160)
* Implements average batch event count and byte size metrics. The collection of such metric could be disabled, enabled for each batch or done on a sample of the total batches [#18000](https://github.com/elastic/logstash/pull/18000)


#### Additional features and enhancements [logstash-9.2.0-more-features]

* Dropped the persistent queue setting queue.checkpoint.interval [#17759](https://github.com/elastic/logstash/pull/17759)
* Reimplements BufferedTokenizer to leverage pure Java classes instead of use JRuby runtime's classes [#17229](https://github.com/elastic/logstash/pull/17229)
* Logging improvement while handling exceptions in the pipeline, ensuring that chained exceptions propagate enough information to be actionable. [#17935](https://github.com/elastic/logstash/pull/17935)
* [Support for using ES|QL queries](https://github.com/logstash-plugins/logstash-filter-elasticsearch/pull/194) in the Elasticsearch filter to add improved flexibility when ingesting data from Elasticsearch is now in Technical Preview. 
* Gauge type metrics, such as current and peak connection counts of Elastic Agent, are now available in the `_node/stats` API response when the `vertices=true` parameter is included. These metrics are particularly useful for monitoring {{ls}} plugin activity on the {{ls}} Integration dashboards [#18090](https://github.com/elastic/logstash/pull/18090)
* Improve Logstash release artifacts file metadata: mtime is preserved when building tar archives [#18091](https://github.com/elastic/logstash/pull/18091)


### Plugins [logstash-plugin-9.2.0-changes]

**Elastic_integration Filter - 9.2.0**

* Logging compatability with Elasticsearch 9.2 [#373](https://github.com/elastic/logstash-filter-elastic_integration/pull/373)
* Utilizes Elasticsearch interfaces via Elasticsearch logstash-bridge [#336](https://github.com/elastic/logstash-filter-elastic_integration/pull/336)

**Translate Filter - 3.5.0**

* Introduce opt-in "yaml_load_strategy => streaming" to stream parse YAML dictionaries. This can hugely reduce the memory footprint when working with large YAML dictionaries.  [#106](https://github.com/logstash-plugins/logstash-filter-translate/pull/106)

**Snmp Integration - 4.1.0**

* Add support for SNMPv3 `context engine ID` and `context name` to the `snmptrap` input [#76](https://github.com/logstash-plugins/logstash-integration-snmp/pull/76)


## 9.1.10 [logstash-9.1.10-release-notes]

### Features and enhancements [logstash-9.1.10-features-enhancements]

No user-facing changes in Logstash core.

### Plugins [logstash-plugin-9.1.10-changes]

::::{Deprecations to Kafka partitioner settings}
The Kafka integration plugin version bundled with this release introduces deprecations for `partitioner` settings in the Kafka output. Check out [Deprecations](/release-notes/deprecations.md) for more information. 
::::

**Beats Input - 7.0.5**

* Upgrade netty 4.1.129 [#525](https://github.com/logstash-plugins/logstash-input-beats/pull/525)

**Http Input - 4.1.4**

* Upgrade netty to 4.1.129 [#203](https://github.com/logstash-plugins/logstash-input-http/pull/203)

**Tcp Input - 7.0.4**

* Upgrade netty to 4.1.129 [#239](https://github.com/logstash-plugins/logstash-input-tcp/pull/239)

**Kafka Integration - 11.8.1**

* Upgrade lz4 dependency [#213](https://github.com/logstash-plugins/logstash-integration-kafka/pull/213)
* Deprecate `default` and `uniform_sticky` options from the `partitioner` option in the Kafka output
[#206](https://github.com/logstash-plugins/logstash-integration-kafka/pull/206)
  * Both options are deprecated in Kafka client 3 and will be removed in the plugin 12.0.0.
* Add `reconnect_backoff_max_ms` option for configuring kafka client [#204](https://github.com/logstash-plugins/logstash-integration-kafka/pull/204)


## 9.1.9 [logstash-9.1.9-release-notes]

### Features and enhancements [logstash-9.1.9-features-enhancements]

Updated logging in JSON format to include pipeline and plugin IDs. [#18470](https://github.com/elastic/logstash/pull/18470)

### Plugins [logstash-plugin-9.1.9-changes]

No user-facing changes in Logstash plugins.


## 9.1.8 [logstash-9.1.8-release-notes]

No user-facing changes in Logstash core.

### Plugins [logstash-plugin-9.1.8-changes]

**Split Filter - 3.1.10**

* Added trace log to track event size expansion [#49](https://github.com/logstash-plugins/logstash-filter-split/pull/49)
* [DOC] Added introductory statement to clarify purpose of the plugin [#43](https://github.com/logstash-plugins/logstash-filter-split/pull/43)

## 9.1.7 [logstash-9.1.7-release-notes]

### Features and enhancements [logstash-9.1.7-features-enhancements]

* Deprecation logs are now written to both the deprecation logger and the standard logger [#18326](https://github.com/elastic/logstash/pull/18326)

### Updates to dependencies [logstash-9.1.7-dependencies]

* Update JDK to 21.0.9 [#18350](https://github.com/elastic/logstash/pull/18350)

### Plugins [logstash-plugin-9.1.7-changes]

**Geoip Filter - 7.3.2**

* Add logs when MaxMind databases fail to deserialize custom field [#235](https://github.com/logstash-plugins/logstash-filter-geoip/pull/235)

**Mutate Filter - 3.5.9**

* Fix `convert` to correctly parse hexadecimal float notation and scientific notation strings into floats and integers [#175](https://github.com/logstash-plugins/logstash-filter-mutate/pull/175)

**Azure_event_hubs Input - 1.5.3**

* Fix an issue when `config_mode => 'advanced'` is set, event hub-specific settings (`initial_position`, `max_batch_size`, `prefetch_count`, `receive_timeout`, `initial_position_look_back`) were being ignored and replaced with global defaults. These settings are now correctly applied per event hub [#104](https://github.com/logstash-plugins/logstash-input-azure_event_hubs/pull/104)

**Rabbitmq Integration - 7.4.1**

* Improve thread safety to avoid race conditions during shutdown [#67](https://github.com/logstash-plugins/logstash-integration-rabbitmq/pull/66)


## 9.1.6 [logstash-9.1.6-release-notes]

No user-facing changes in Logstash core.

### Plugins [logstash-plugin-9.1.6-changes]

**Csv Output - 3.0.11**

* Docs: Correct code snippet [#28](https://github.com/logstash-plugins/logstash-output-csv/pull/28)

## 9.1.5 [logstash-9.1.5-release-notes]

No user-facing changes in Logstash core.

### Plugins [logstash-plugin-9.1.5-changes]

**Elasticsearch Filter - 4.3.1**

* Added support for encoded and non-encoded api-key formats on plugin configuration [#203](https://github.com/logstash-plugins/logstash-filter-elasticsearch/pull/203)

**Elasticsearch Input - 5.2.1**

* Added support for encoded and non-encoded api-key formats on plugin configuration [#237](https://github.com/logstash-plugins/logstash-input-elasticsearch/pull/237)

**Jdbc Integration - 5.6.1**

* Fixes an issue where the `jdbc_static` filter's throughput was artificially limited to 4 concurrent queries, causing the plugin to become a bottleneck in pipelines with more than 4 workers. Each instance of the plugin is now limited to 16 concurrent queries, with increased timeouts to eliminate enrichment failures. [#187](https://github.com/logstash-plugins/logstash-integration-jdbc/pull/187)

**Elasticsearch Output - 12.0.7**

* Support both, encoded and non encoded api-key formats on plugin configuration [#1223](https://github.com/logstash-plugins/logstash-output-elasticsearch/pull/1223)

## 9.1.4 [logstash-9.1.4-release-notes]

### Features and enhancements [logstash-9.1.4-features-enhancements]

##### ES|QL Support in Elasticsearch Filter (Technical Preview)

* [Support for using ES|QL queries](https://github.com/logstash-plugins/logstash-filter-elasticsearch/pull/194) in the Elasticsearch filter to add improved flexibility when ingesting data from Elasticsearch is now in Technical Preview. 

### Fixes [logstash-9.1.4-fixes]

* Gauge type metrics, such as current and peak connection counts of Elastic Agent, are now available in the `_node/stats` API response when the `vertices=true` parameter is included. These metrics are particularly useful for monitoring {{ls}} plugin activity on the {{ls}} Integration dashboards [#18090](https://github.com/elastic/logstash/pull/18090)
* Improve {{ls}} release artifacts file metadata: mtime is preserved when building tar archives [#18091](https://github.com/elastic/logstash/pull/18091)


### Plugins [logstash-plugin-9.1.4-changes]

**Elasticsearch Filter - 4.3.0**

* ES|QL support [#194](https://github.com/logstash-plugins/logstash-filter-elasticsearch/pull/194)

**Beats Input - 7.0.3**

* Upgrade netty 4.1.126 [#517](https://github.com/logstash-plugins/logstash-input-beats/pull/517)

**Http Input - 4.1.3**

* Upgrade netty to 4.1.126 [#198](https://github.com/logstash-plugins/logstash-input-http/pull/198)

**Jms Input - 3.3.1**

* Fixed a regression introduced in 3.3.0 where `add_field` is no longer enriching events [#59](https://github.com/logstash-plugins/logstash-input-jms/pull/59)

**Tcp Input - 7.0.3**

* Upgrade netty to 4.1.126 [#235](https://github.com/logstash-plugins/logstash-input-tcp/pull/235)

**Kafka Integration - 11.6.4**

* Display exception chain comes from kafka client [#200](https://github.com/logstash-plugins/logstash-integration-kafka/pull/200)

## 9.1.3 [logstash-9.1.3-release-notes]

### Features and enhancements [logstash-9.1.3-features-enhancements]

* Logging improvement while handling exceptions in the pipeline, ensuring that chained exceptions propagate enough information to be actionable. [#17935](https://github.com/elastic/logstash/pull/17935)

### Plugins [logstash-plugin-9.1.3-changes]

No change to the plugins in this release.

## 9.1.2 [logstash-9.1.2-release-notes]

No user-facing changes in Logstash core.

### Plugins [logstash-plugin-9.1.2-changes]

No change to the plugins in this release.

## 9.1.1 [logstash-9.1.1-release-notes]

### Features and enhancements [logstash-9.1.1-features-enhancements]

No user-facing changes in Logstash core.

### Plugins [logstash-plugin-9.1.1-changes]

**Elastic_integration Filter - 9.1.1**

* Add terminate processor support [#345](https://github.com/elastic/logstash-filter-elastic_integration/pull/345)

**Translate Filter - 3.4.3**

* Allow YamlFile's Psych::Parser and Visitor instances to be garbage collected [#104](https://github.com/logstash-plugins/logstash-filter-translate/pull/104)

**Xml Filter - 4.3.2**

* Update Nokogiri dependency version [#89](https://github.com/logstash-plugins/logstash-filter-xml/pull/89)

**Azure_event_hubs Input - 1.5.2**

* Updated JWT dependency [#101](https://github.com/logstash-plugins/logstash-input-azure_event_hubs/pull/101)

**Snmp Integration - 4.0.7**

* FIX: The `snmptrap` input now correctly enforces the user security level set by `security_level` config, and drops received events that do not match the configured value [#75](https://github.com/logstash-plugins/logstash-integration-snmp/pull/75)

**Elasticsearch Output - 12.0.6**

* Add headers reporting uncompressed size and doc count for bulk requests [#1217](https://github.com/logstash-plugins/logstash-output-elasticsearch/pull/1217)

## 9.1.0 [logstash-9.1.0-release-notes]

### Features and enhancements [logstash-9.1.0-features-enhancements]

* Significantly improves write speeds to the persistent queue (PQ) when a pipeline's workers are caught up with already-written events [#17791](https://github.com/elastic/logstash/pull/17791)
* Eliminated log warning about unknown gauge metric type when using pipeline-to-pipeline. [#17721](https://github.com/elastic/logstash/pull/17721)
* Improve plugins remove command to support multiple plugins [#17030](https://github.com/elastic/logstash/pull/17030)
* Deprecated the persistent queue setting `queue.checkpoint.interval`[#17759](https://github.com/elastic/logstash/pull/17759), which was found to have no effect. This will be removed in a future Logstash release.
* Logstash now ships with JRuby 9.4.13.0 to leveragle latest features and improvements in the 9.4 series [#17696](https://github.com/elastic/logstash/pull/17696)
* Enhanced keystore validation to prevent the creation of secrets in an invalid format [#17351](https://github.com/elastic/logstash/pull/17351)

##### ES|QL Support in Elasticsearch Input (Technical Preview)

* [Support](https://github.com/logstash-plugins/logstash-input-elasticsearch/pull/235) for using ES|QL queries in the Elasticsearch input to add improved flexibility when ingesting data from Elasticsearch is now in Technical Preview. 
* Logstash OSS and Full docker images are now based on Ubuntu 24.04.

#### Field Tracking Support in Elasticsearch Input (Technical Preview)

The Elasticsearch Input now provides [support](https://github.com/logstash-plugins/logstash-input-elasticsearch/pull/205) for field value tracking, persisted to disk on each `search_after` page. This is useful to track new data being written to an index or series of indices.
### Updates to dependencies [logstash-9.1.0-dependencies]

* Update JDK to 21.0.7+6 [#17591](https://github.com/elastic/logstash/pull/17591)

### Plugins [logstash-plugin-9.1.0-changes]

**Elastic Integration Filter - 9.1.0**

* Introduces `proxy` param to support proxy [#316](https://github.com/elastic/logstash-filter-elastic_integration/pull/316)
* Embeds Ingest Node components from Elasticsearch 9.1

**Elasticsearch Filter - 4.2.0**

* Add `target` configuration option to store the result into it [#196](https://github.com/logstash-plugins/logstash-filter-elasticsearch/pull/196)

**Elasticsearch Input - 5.2.0**

* Add "cursor"-like index tracking [#205](https://github.com/logstash-plugins/logstash-input-elasticsearch/pull/205)
* ES|QL support [#233](https://github.com/logstash-plugins/logstash-input-elasticsearch/pull/233)

**Elasticsearch Output - 12.0.5**

* Docs: update Cloud terminology [#1212](https://github.com/logstash-plugins/logstash-output-elasticsearch/pull/1212)
* Change connection log entry from `WARN` to `INFO` when connecting during register phase [#1211](https://github.com/logstash-plugins/logstash-output-elasticsearch/pull/1211)

**JDBC Integration - 5.6.0**

* Support other rufus scheduling options in JDBC Input [#183](https://github.com/logstash-plugins/logstash-integration-jdbc/pull/183)

**JMS Input - 3.3.0**

* Added support for decoding multiple events from text or binary messages when using a codec that produces multiple events [#56](https://github.com/logstash-plugins/logstash-input-jms/pull/56)

**Kafka Integration - 11.6.3**

* Update kafka client to `3.9.1` [#193](https://github.com/logstash-plugins/logstash-integration-kafka/pull/193)
* Docs: fixed setting type reference for `sasl_iam_jar_paths` [#192](https://github.com/logstash-plugins/logstash-integration-kafka/pull/192)
* Expose the SASL client callback class setting to the Logstash configuration [#177](https://github.com/logstash-plugins/logstash-integration-kafka/pull/177)
* Adds a mechanism to load AWS IAM authentication as SASL client libraries at startup [#178](https://github.com/logstash-plugins/logstash-integration-kafka/pull/178)

**Xml Filter - 4.3.1**

* Update Nokogiri dependency version [#88](https://github.com/logstash-plugins/logstash-filter-xml/pull/88)

**Tcp Output - 7.0.1**

* Call connection check after connect [#61](https://github.com/logstash-plugins/logstash-output-tcp/pull/61)

## 9.0.8 [logstash-9.0.8-release-notes]

No user-facing changes in Logstash core.

### Plugins [logstash-plugin-9.0.8-changes]

**Elasticsearch Output - 12.0.7**

* Support both, encoded and non-encoded api-key formats on plugin configuration [#1223](https://github.com/logstash-plugins/logstash-output-elasticsearch/pull/1223)


## 9.0.7 [logstash-9.0.7-release-notes]

### Fixes [logstash-9.0.7-fixes]

* Gauge type metrics, such as current and peak connection counts of Elastic Agent, are now available in the `_node/stats` API response when the `vertices=true` parameter is included. These metrics are particularly useful for monitoring {{ls}} plugin activity on the {{ls}} Integration dashboards. [#18089](https://github.com/elastic/logstash/pull/18089)
* Improve logstash release artifacts file metadata: mtime is preserved when building tar archives. [#18111](https://github.com/elastic/logstash/pull/18111)

### Plugins [logstash-plugin-9.0.7-changes]

**Beats Input - 7.0.3**

* Upgrade netty 4.1.126 [#517](https://github.com/logstash-plugins/logstash-input-beats/pull/517)

**Http Input - 4.1.3**

* Upgrade netty to 4.1.126 [#198](https://github.com/logstash-plugins/logstash-input-http/pull/198)

**Tcp Input - 7.0.3**

* Upgrade netty to 4.1.126 [#235](https://github.com/logstash-plugins/logstash-input-tcp/pull/235)

**Kafka Integration - 11.6.4**

* Display exception chain comes from kafka client [#200](https://github.com/logstash-plugins/logstash-integration-kafka/pull/200)

## 9.0.6 [logstash-9.0.6-release-notes]

### Features and enhancements [logstash-9.0.6-features-enhancements]

* Logging improvement while handling exceptions in the pipeline, ensuring that chained exceptions propagate enough information to be actionable. [#17934](https://github.com/elastic/logstash/pull/17934)

### Plugins [logstash-plugin-9.0.6-changes]

No change to the plugins in this release.

## 9.0.5 [logstash-9.0.5-release-notes]

### Features and enhancements [logstash-9.0.5-features-enhancements]

No user-facing changes in Logstash core.

### Plugins [logstash-plugin-9.0.5-changes]

**Elastic_integration Filter - 9.0.2**

* Adds support for missing `terminate` processor [#345](https://github.com/elastic/logstash-filter-elastic_integration/pull/345)

**Translate Filter - 3.4.3**

* FIX: Reduces memory consumption when configured with a YAML dictionary file by allowing YamlFile's Psych::Parser and Visitor instances to be garbage collected [#104](https://github.com/logstash-plugins/logstash-filter-translate/pull/104)

**Xml Filter - 4.3.2**

* Update Nokogiri dependency version [#89](https://github.com/logstash-plugins/logstash-filter-xml/pull/89)

**Azure_event_hubs Input - 1.5.2**

* Updated JWT dependency [#101](https://github.com/logstash-plugins/logstash-input-azure_event_hubs/pull/101)

**Snmp Integration - 4.0.7**

* FIX: The `snmptrap` input now correctly enforces the user security level set by `security_level` config, and drops received events that do not match the configured value [#75](https://github.com/logstash-plugins/logstash-integration-snmp/pull/75)

**Elasticsearch Output - 12.0.6**

* Add headers reporting uncompressed size and doc count for bulk requests [#1217](https://github.com/logstash-plugins/logstash-output-elasticsearch/pull/1217)
* [DOC] Fix link to Logstash DLQ docs [#1214](https://github.com/logstash-plugins/logstash-output-elasticsearch/pull/1214)

## 9.0.4 [logstash-9.0.4-release-notes]

### Fixes [logstash-9.0.4-fixes]

* Significantly improves write speeds to the persistent queue (PQ) when a pipeline's workers are caught up with already-written events [#17791](https://github.com/elastic/logstash/pull/17791)
* Eliminated log warning about unknown gauge metric type when using pipeline-to-pipeline. [#17721](https://github.com/elastic/logstash/pull/17721)

### Plugins [logstash-plugin-9.0.4-changes]

**Elastic_integration Filter - 9.0.1**

* Introduces `proxy` config to support proxy URI to connect to Elasticsearch. [#320](https://github.com/elastic/logstash-filter-elastic_integration/pull/320)

**Elasticsearch Output - 12.0.4**

* Docs: update Cloud terminology [#1212](https://github.com/logstash-plugins/logstash-output-elasticsearch/pull/1212)

## 9.0.3 [logstash-9.0.3-release-notes]

No user-facing changes in Logstash core.

### Plugins [logstash-plugin-9.0.3-changes]

**Kafka Integration - 11.6.3**

* Update kafka client to `3.9.1` [#193](https://github.com/logstash-plugins/logstash-integration-kafka/pull/193)

## 9.0.2 [logstash-9.0.2-release-notes]

No user-facing changes in Logstash core.

### Plugins [logstash-plugin-9.0.2-changes]

**Kafka Integration - 11.6.2**

* Docs: fixed setting type reference for `sasl_iam_jar_paths` [#192](https://github.com/logstash-plugins/logstash-integration-kafka/pull/192)
* Expose the SASL client callback class setting to the Logstash configuration [#177](https://github.com/logstash-plugins/logstash-integration-kafka/pull/177)
* Adds a mechanism to load AWS IAM authentication as SASL client libraries at startup [#178](https://github.com/logstash-plugins/logstash-integration-kafka/pull/178)

## 9.0.1 [logstash-9.0.1-release-notes]

::::{important}
The 9.0.1 release contains fixes for potential security vulnerabilities. 
Check out the [security advisory](https://discuss.elastic.co/c/announcements/security-announcements/31) for details.
::::

### Features and enhancements [logstash-9.0.1-features-enhancements]

* Enhanced keystore validation to prevent the creation of secrets in an invalid format [#17351](https://github.com/elastic/logstash/pull/17351)

### Updates to dependencies [logstash-9.0.1-dependencies]

* Update JDK to 21.0.7+6 [#17591](https://github.com/elastic/logstash/pull/17591)

### Plugins [logstash-plugin-9.0.1-changes]

**Xml Filter - 4.3.1**

* Update Nokogiri dependency version [#88](https://github.com/logstash-plugins/logstash-filter-xml/pull/88)

**Elasticsearch Output - 12.0.3**

* Change connection log entry from `WARN` to `INFO` when connecting during register phase [#1211](https://github.com/logstash-plugins/logstash-output-elasticsearch/pull/1211)

**Tcp Output - 7.0.1**

* Call connection check after connect [#61](https://github.com/logstash-plugins/logstash-output-tcp/pull/61)

## 9.0.0 [logstash-900-release-notes]

### Features and enhancements [logstash-900-features-enhancements]

* Use UBI9 as base image [#17174](https://github.com/elastic/logstash/pull/17174)
* Improve plugins remove command to support multiple plugins [#17030](https://github.com/elastic/logstash/pull/17030)
* Allow concurrent Batch deserialization [#17050](https://github.com/elastic/logstash/pull/17050)

### Fixes [logstash-900-fixes]

* Fix pqcheck and pqrepair on Windows [#17210](https://github.com/elastic/logstash/pull/17210)
* Fix empty node stats pipelines [#17185](https://github.com/elastic/logstash/pull/17185)

### Plugins [logstash-plugin-900-changes]

**elastic_integration Filter - 9.0.0**

* 9.0 prerelease compatible plugin version [#265](https://github.com/elastic/logstash-filter-elastic_integration/pull/265)

**Elasticsearch Filter - 4.1.0**

* Remove deprecated SSL settings [#183](https://github.com/logstash-plugins/logstash-filter-elasticsearch/pull/183)

**Http Filter - 2.0.0**

* Remove deprecated SSL settings [#54](https://github.com/logstash-plugins/logstash-filter-http/pull/54)

**Beats Input - 7.0.1**

* Remove deprecated SSL settings [#508](https://github.com/logstash-plugins/logstash-input-beats/pull/508)

**Elastic_serverless_forwarder Input - 2.0.0**

* Remove deprecated SSL settings [#11](https://github.com/logstash-plugins/logstash-input-elastic_serverless_forwarder/pull/11)

* Promote from technical preview to GA [#10](https://github.com/logstash-plugins/logstash-input-elastic_serverless_forwarder/pull/10)

**Elasticsearch Input - 5.0.0**

* Remove deprecated SSL settings [#213](https://github.com/logstash-plugins/logstash-input-elasticsearch/pull/213)

**Http Input - 4.1.0**

* Remove deprecated SSL settings [#182](https://github.com/logstash-plugins/logstash-input-http/pull/182)

**Http_poller Input - 6.0.0**

* Remove deprecated SSL settings [#149](https://github.com/logstash-plugins/logstash-input-http_poller/pull/149)

**Tcp Input - 7.0.0**

* Remove deprecated SSL settings [#228](https://github.com/logstash-plugins/logstash-input-tcp/pull/228)

**Kafka Integration - 11.6.0**

* Support additional `oauth` and `sasl` configuration options for configuring kafka client [#189](https://github.com/logstash-plugins/logstash-integration-kafka/pull/189)

**Snmp Integration - 4.0.6**

* [DOC] Fix typo in snmptrap migration section [#74](https://github.com/logstash-plugins/logstash-integration-snmp/pull/74)

**Elasticsearch Output - 12.0.2**

* Remove deprecated SSL settings [#1197](https://github.com/logstash-plugins/logstash-output-elasticsearch/pull/1197)

**Http Output - 6.0.0**

* Remove deprecated SSL settings [#147](https://github.com/logstash-plugins/logstash-output-http/pull/147)

**Tcp Output - 7.0.0**

* Remove deprecated SSL settings [#58](https://github.com/logstash-plugins/logstash-output-tcp/pull/58)