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

## 9.2.0 [logstash-9.2.0-release-notes]

### Features and enhancements [logstash-9.2.0-features-enhancements]

---------- GENERATED CONTENT STARTS HERE ------------
=== Logstash Pull Requests with label v9.2.0

=== Logstash Commits between 9.2 and 9.1.5

0f8c7ba06 - Documentation for batch's event metrics (current and average) (#18017) (2 weeks ago) <Andrea Selva>
425478cd6 - metrics: add gauge with compression goal if enabled (#18230) (2 weeks ago) <Rye Biesemeyer>
1b3b3eeb0 - Pq compression user metrics (#18227) (2 weeks ago) <Rye Biesemeyer>
88b853aff - (origin/mergify/bp/main/pr-18168) metric: improve accuracy of timer metric under contention (#18219) (2 weeks ago) <Rye Biesemeyer>
75eca8475 - metrics: add support for user-defined metrics (#18218) (2 weeks ago) <Rye Biesemeyer>
a1522385b - PQ: Add support for event-level compression using ZStandard (ZSTD) (#18121) (2 weeks ago) <Rye Biesemeyer>
fdeb6a0b9 - Implements current batch event count and byte size metrics (#18160) (3 weeks ago) <Andrea Selva>
d29021800 - Measure average batch byte size and event count (#18000) (3 weeks ago) <Andrea Selva>
f3212484f - PQ settings refactor: propagate builder upward (#18180) (4 weeks ago) <Rye Biesemeyer>

6aa265dcd - Moved Ruby Password setting to Java implementation (#18183) (4 weeks ago) <Andrea Selva>
cd71a4b18 - Rename Java settings classes to <Name>Setting (#18171) (4 weeks ago) <Andrea Selva>
b8bc4d8de - Move Port and PortRange Ruby settings to Java (#17964) (4 weeks ago) <Andrea Selva>

ba0787817 - pq: activate stringref extension for more-compact PQ representation (#17849) (6 weeks ago) <Rye Biesemeyer>


aabf84ba4 - Convert Ruby Integer and PositiveInteger settings classes to Java (#17460) (9 weeks ago) <Andrea Selva>
0b4360183 - Update source/target to Java17 (#17943) (10 weeks ago) <Rye Biesemeyer>

9b9790cd1 - pipeline logging: add cause chain when logging (#16677) (10 weeks ago) <Rye Biesemeyer>

3b13df1d6 - cli: add hidden command-line flag for overriding settings (#17582) (2 months ago) <Rye Biesemeyer>
1d565c0af - Removal of Ruby bridge classes for Gauge and Counter (#17858) (2 months ago) <Andrea Selva>


521af3bd4 - Obsolete PQ setting queue.checkpoint.interval  (#17759) (3 months ago) <kaisecheng>

ddd519cc8 - pq: reduce read contention when caught up (#17765) (3 months ago) <Rye Biesemeyer>

ed4022057 - Implement BufferedTokenizer to return an iterable that can verify size limit for every token emitted (#17229) (4 months ago) <Andrea Selva>


=== Logstash Plugin Release Changelogs ===
Computed from "git diff v9.1.5..9.2 *.release"
Changed plugin versions:
logstash-filter-elastic_integration: 9.1.1 -> 9.2.0
logstash-filter-translate: 3.4.3 -> 3.5.0
logstash-integration-snmp: 4.0.7 -> 4.1.0
---------- GENERATED CONTENT ENDS HERE ------------

### Plugins [logstash-plugin-9.2.0-changes]

**Elastic_integration Filter - 9.2.0**

404: Not Found

**Translate Filter - 3.5.0**

* Introduce opt-in "yaml_load_strategy => streaming" to stream parse YAML dictionaries [#106](https://github.com/logstash-plugins/logstash-filter-translate/pull/106)

**Snmp Integration - 4.1.0**

* Add support for SNMPv3 `context engine ID` and `context name` to the `snmptrap` input [#76](https://github.com/logstash-plugins/logstash-integration-snmp/pull/76)


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