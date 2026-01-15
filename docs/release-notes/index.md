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

## 9.2.5 [logstash-9.2.5-release-notes]

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

## 9.3.0 [logstash-9.3.0-release-notes]

### Features and enhancements [logstash-9.3.0-features-enhancements]

---------- GENERATED CONTENT STARTS HERE ------------
=== Logstash Pull Requests with label v9.3.0

=== Logstash Commits between 9.3 and 9.2.4

Computed with "git log --pretty=format:'%h -%d %s (%cr) <%an>' --abbrev-commit --date=relative v9.2.4..9.3"

269a0f4b2 - (HEAD -> 9.3, origin/9.3) Downgrade kafka-integration to 11.8.1 to avoid breaking backward compatibility. (#18574) (2 days ago) <Mashhur>
0c8b305b2 - Upgrade elastic_integration plugin after release. (#18535) (2 weeks ago) <Mashhur>
b3b3f02ee - Fix, clean batch metrics on pipeline shutdown (#18515) (#18521) (2 weeks ago) <mergify[bot]>
5b0b195fb - Update patch plugin versions in gemfile lock (#18531) (3 weeks ago) <github-actions[bot]>
30c4a90c4 - Stop tests from polluting maven settings (#18525) (#18530) (3 weeks ago) <mergify[bot]>
8302f8bfe - bump lock file for 9.3 (#18518) (4 weeks ago) <github-actions[bot]>
55eb62bb8 - Revert "Keep psych minor version in line with jruby 9.4.13.0 (#18507) (#18508)" (#18517) (4 weeks ago) <Cas Donoghue>
1be926e59 - [9.3 release] Copy gemfile.lock from 9.2 and upgrade dependencies (#18506) (4 weeks ago) <Mashhur>
a55bc73ac - Keep psych minor version in line with jruby 9.4.13.0 (#18507) (#18508) (4 weeks ago) <mergify[bot]>
016ec9dbf - [main] (backport #18480) Release notes for 9.2.3 (#18501) (4 weeks ago) <mergify[bot]>
d174a5673 - [main] (backport #18479) Release notes for 9.1.9 (#18500) (4 weeks ago) <mergify[bot]>
a540784be - Plugins snyk scanning followups (#18498) (4 weeks ago) <Mashhur>
a89e530db - Logstash plugins snyk scan pipeline. (#18496) (4 weeks ago) <Mashhur>
9d76738b1 - chore: deps(updatecli): Bump updatecli version to v0.112.0 (#18495) (4 weeks ago) <github-actions[bot]>
3e3e75ddd - bk(pull-requests.json): run faster if unrelated changes to the CI project (#18490) (4 weeks ago) <Victor Martinez>
abb0d1a7b - Bump anchore/scan-action in the github-actions group across 1 directory (#18494) (4 weeks ago) <dependabot[bot]>
39cbdce70 - (origin/mergify/bp/main/pr-18493, origin/mergify/bp/main/pr-18492) Doc: Update Logstash security settings (#18356) (5 weeks ago) <Karen Metts>
dc83bda54 - Support wait_for_status and timeout query params on root endpoint (#18377) (5 weeks ago) <Emily S>
e0acfe744 - Exposes average batch metrics at 1, 5 and 15 minutes time window. (#18460) (5 weeks ago) <Andrea Selva>
cfa4fb9de - Validate supplied branch and tag exist for RN gen (#18481) (5 weeks ago) <Cas Donoghue>
e08abb8c0 - Remove duplicate gems when producting logstash artifacts (#18340) (5 weeks ago) <Cas Donoghue>
279171b79 - Include pipeline and plugin IDs to the JSON logs. (#18470) (5 weeks ago) <Mashhur>
4ef52c227 - Chore: spread use of ManualAdvanceClock to avoid similar test class creation (#18467) (5 weeks ago) <Andrea Selva>
3659b6f9a - (origin/mergify/bp/main/pr-18466, origin/mergify/bp/main/pr-18461) Moved Ruby ValidatedPassword setting to Java implementation (#18185) (6 weeks ago) <Andrea Selva>
10c87a639 - Doc: Add elastic-integration filter tutorial (#18229) (6 weeks ago) <Karen Metts>
b15c6c50f - Rewrite Env2yaml in java instead of Go (#18423) (6 weeks ago) <Cas Donoghue>
a69f5efba - chore: deps(updatecli): Bump updatecli version to v0.111.0 (#18450) (6 weeks ago) <github-actions[bot]>
f7fbfbfb8 - Bump anchore/scan-action in the github-actions group across 1 directory (#18449) (6 weeks ago) <dependabot[bot]>
88585c5cf - Bump the github-actions group across 1 directory with 2 updates (#18439) (7 weeks ago) <dependabot[bot]>
934740bdf - management: confirm server-side filtering 404s (#18265) (8 weeks ago) <Rye Biesemeyer>
4a1c7bf3e - updatecli: manage UBI and updatecli versions (#18427) (8 weeks ago) <Victor Martinez>
f05d515e4 - chore: deps(updatecli): Bump updatecli version to v0.110.3 (#18431) (8 weeks ago) <github-actions[bot]>
84db0b012 - bump: ubi 9.7 (#18426) (8 weeks ago) <Victor Martinez>
4abb46c45 - Release notes for 9.2.1 (#18404) (#18418) (9 weeks ago) <mergify[bot]>
b49d49bba - [main] (backport #18405) Release notes for 9.1.7 (#18417) (9 weeks ago) <mergify[bot]>
4963c0b20 - Ensure java updator runs on all active branches (#18408) (2 months ago) <Cas Donoghue>
3ca739501 - simplify x-pack/build.gradle (#18381) (2 months ago) <João Duarte>
d9fda3795 - Use logstash-versions.yml for observabilitySRE stack versions (#18375) (2 months ago) <Cas Donoghue>
aaa532604 - Upgrade JDK to 21.0.9 (#18350) (2 months ago) <Mashhur>
90c447677 - [DOCS] Fix OpenAPI enum error (#18344) (2 months ago) <Lisa Cawley>
bf89f43b7 - chore: remove test file for exhaustive tests and normalise github commands (#18384) (3 months ago) <Victor Martinez>
02aa5e13e - bk(smart exhaustive tests): tune the steps to support GH comments and changesets (#18383) (3 months ago) <Victor Martinez>
be64ebfdd - bk: fix regex and add new file (#18382) (3 months ago) <Victor Martinez>
fc9ad7fd6 - feat(ci): support exhaustive tests for PRs (code changes or GH comment) (#18327) (3 months ago) <Victor Martinez>
915b69fee - Modify logger config to link deprecation logger to root logger by default (#18326) (3 months ago) <Álex Cámara Lara>
6a17987fa - Add PQ unable to start in `9.2.0` known issue (#18369) (3 months ago) <Rob Bavey>
ee6813136 - Actually raise a PR when java-bump is detected (#18351) (3 months ago) <Cas Donoghue>
c6dba082f - Set 45m timeout to exhaustive pipeline jobs. (#18362) (3 months ago) <Mashhur>
6c48e519f - make queue_max_bytes a long again allowing queues bigger than 2GB (#18366) (3 months ago) <João Duarte>
c10b871a2 - Bump anchore/scan-action in the github-actions group across 1 directory (#18365) (3 months ago) <dependabot[bot]>
163bc72da - Logstash 9.2.0 release notes updates (#18360) (3 months ago) <Karen Metts>
391217abc - Fixes the NPE when stats info doesn't have queue type entry. (#18331) (3 months ago) <Mashhur>
458efabb8 - retry catalog queries and jdk downloads (#18345) (3 months ago) <João Duarte>
21ac3d8dc - Release notes for 9.2.0 (#18313) (#18339) (3 months ago) <mergify[bot]>
67c7386bd - Release notes for 9.1.6 (#18334) (#18338) (3 months ago) <mergify[bot]>
b6af3151f - Deprecate config.reload.* as pipeline-level settings (#18312) (3 months ago) <Emily S>
a83b7a4ff - Add encoded/non-encoded auth method to x-pack unit tests (#18307) (3 months ago) <Álex Cámara Lara>
0b661d992 - Bump the github-actions group across 1 directory with 2 updates (#18320) (3 months ago) <dependabot[bot]>
fc7ba9f25 - Handle GH org for elastic_integration plugin (#18315) (3 months ago) <Cas Donoghue>
08f4c5270 - Adds integration test for the `_health_report` and `_node/plugins` APIs. (#18306) (3 months ago) <Mashhur>
15b4e05e3 - Move invokedynamic and log4j isThreadContextMapInheritable from jvm.options to code  (#18296) (3 months ago) <Emily S>
8f4014b44 - (origin/mergify/bp/main/pr-18292, origin/mergify/bp/main/pr-18291) Doc: Update docs for testing for boolean fields (#18271) (3 months ago) <Karen Metts>
cbef0782e - ci: remove sonarqube (#18273) (3 months ago) <Victor Martinez>
819474f8a - [main] (backport #18247) Release notes for 9.0.8 (#18270) (3 months ago) <mergify[bot]>
a120ab874 - Release notes for 9.1.5 (#18248) (#18267) (3 months ago) <mergify[bot]>
8a92bbb62 - Downgrade gradle to coninute testing on windows server 2016 (#18263) (3 months ago) <Cas Donoghue>
1150f8899 - Bump logstash version 9.3.0 (#18241) (4 months ago) <github-actions[bot]>
a3228e2dd - Ensure docs gen inserts at correct place in file (#18250) (4 months ago) <Cas Donoghue>
1356c668e - Rewrite Password setting class in Java (second attempt) (#18231) (4 months ago) <Andrea Selva>
a994c7cb6 - Remove redundant testing and circular dependency from docker acceptance testing (#18181) (4 months ago) <Cas Donoghue>

=== Logstash Plugin Release Changelogs ===
Computed from "git diff v9.2.4..9.3 *.release"
Changed plugin versions:
logstash-codec-avro: 3.4.1 -> 3.5.0
logstash-filter-cidr: 3.1.3 -> 3.2.0
logstash-filter-elastic_integration: 9.2.0 -> 9.3.0
logstash-integration-snmp: 4.1.0 -> 4.2.0
logstash-output-elasticsearch: 12.0.7 -> 12.1.1
---------- GENERATED CONTENT ENDS HERE ------------

### Plugins [logstash-plugin-9.3.0-changes]

**Avro Codec - 3.5.0**

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

**Cidr Filter - 3.2.0**

* feature: Add address_field config option to handle nested fields

**Elastic_integration Filter - 9.3.0**

* Embeds Ingest Node components from Elasticsearch 9.3 [#378](https://github.com/elastic/logstash-filter-elastic_integration/pull/378)

**Snmp Integration - 4.2.0**

* Add AES256 with 3DES extension support for `priv_protocol` [#78](https://github.com/logstash-plugins/logstash-integration-snmp/pull/78)

**Elasticsearch Output - 12.1.1**

* Remove duplicated deprecation log entry [#1232](https://github.com/logstash-plugins/logstash-output-elasticsearch/pull/1232)

* Add drop_error_types config option to not retry after certain error types [#1228](https://github.com/logstash-plugins/logstash-output-elasticsearch/pull/1228)


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

#### Persistent queue (PQ} compression [logstash-9.2.0-pq-compression]

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


# 9.1.9 [logstash-9.1.9-release-notes]

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
* Improve logstash release artifacts file metadata: mtime is preserved when buiilding tar archives [#18091](https://github.com/elastic/logstash/pull/18091)


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