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

Computed with "git log --pretty=format:'%h -%d %s (%cr) <%an>' --abbrev-commit --date=relative v9.1.5..9.2"

3cf4222b4 - (HEAD -> 9.2, origin/9.2) Adds integration test for the `_health_report` and `_node/plugins` APIs. (#18306) (#18311) (8 hours ago) <mergify[bot]>
d32268785 - Update rack to 3.2.3 (#18300) (31 hours ago) <Mashhur>
da313459d - Doc: Update docs for testing for boolean fields (#18271) (#18292) (8 days ago) <mergify[bot]>
bf6cf7b88 - Update rack rubygem dep to 3.2.2 (#18293) (8 days ago) <Cas Donoghue>
6b7e1cc01 - Remove redundant testing and circular dependency from docker acceptance testing (#18181) (#18255) (8 days ago) <mergify[bot]>
06a09d01e - Downgrade gradle to coninute testing on windows server 2016 (#18263) (#18278) (8 days ago) <mergify[bot]>
ee9a0ec3a - ci: remove sonarqube (#18273) (#18286) (9 days ago) <mergify[bot]>
98c54cf44 - [9.2] (backport #18247) Release notes for 9.0.8 (#18269) (9 days ago) <mergify[bot]>
f333f73ba - Release notes for 9.1.5 (#18248) (#18266) (9 days ago) <mergify[bot]>
e9df375de - Ensure docs gen inserts at correct place in file (#18250) (#18259) (9 days ago) <mergify[bot]>
587d2560b - Take up 9.2 version of elastic_integration plugin (#18261) (13 days ago) <Cas Donoghue>
bcdc991e6 - Add lockfile for new 9.2 branch (#18242) (2 weeks ago) <Cas Donoghue>
4934f0839 - (origin/mergify/bp/main/pr-18240) Fix heading (#18237) (2 weeks ago) <Karen Metts>
0f8c7ba06 - Documentation for batch's event metrics (current and average) (#18017) (2 weeks ago) <Andrea Selva>
425478cd6 - metrics: add gauge with compression goal if enabled (#18230) (2 weeks ago) <Rye Biesemeyer>
1b3b3eeb0 - Pq compression user metrics (#18227) (2 weeks ago) <Rye Biesemeyer>
88b853aff - (origin/mergify/bp/main/pr-18168) metric: improve accuracy of timer metric under contention (#18219) (2 weeks ago) <Rye Biesemeyer>
75eca8475 - metrics: add support for user-defined metrics (#18218) (2 weeks ago) <Rye Biesemeyer>
a1522385b - PQ: Add support for event-level compression using ZStandard (ZSTD) (#18121) (2 weeks ago) <Rye Biesemeyer>
0f9b2fe46 - [DOCS] Fix substitution variables (#18224) (3 weeks ago) <Lisa Cawley>
46bf75eed - (origin/mergify/bp/main/pr-18223) [Docs] Add hyphen to the pipeline ID restriction description. (#18216) (3 weeks ago) <Mashhur>
fdeb6a0b9 - Implements current batch event count and byte size metrics (#18160) (3 weeks ago) <Andrea Selva>
2fab5f469 - Replace buildkite jdk version check w/GH action (#17945) (3 weeks ago) <Cas Donoghue>
ecaf1fdd4 - Cover the warn password policy usage of ValidatedPassword setting (#18203) (3 weeks ago) <Andrea Selva>
ad200323b - GH action for updating logstash version (#18035) (3 weeks ago) <Cas Donoghue>
132f917ea - Update logstash_project_board.yml (#18116) (3 weeks ago) <Rob Bavey>
e6e7f87a8 - Remove uncommented line erroneously committed. (#18204) (3 weeks ago) <Andrea Selva>
d29021800 - Measure average batch byte size and event count (#18000) (3 weeks ago) <Andrea Selva>
105eecca7 - (origin/mergify/bp/main/pr-18021) Revert "Moved Ruby Password setting to Java implementation (#18183)" (#18199) (3 weeks ago) <Cas Donoghue>
c2851a958 - bk: update junit-annotate to run faster (#18193) (3 weeks ago) <Copilot>
ad42337ee - Bump anchore/scan-action from 6 to 7 in the github-actions group across 1 directory (#18195) (3 weeks ago) <dependabot[bot]>
f3212484f - PQ settings refactor: propagate builder upward (#18180) (4 weeks ago) <Rye Biesemeyer>
8228fe5dc - Release notes for 9.1.4 (#18159) (#18190) (4 weeks ago) <mergify[bot]>
6aa265dcd - Moved Ruby Password setting to Java implementation (#18183) (4 weeks ago) <Andrea Selva>
cd71a4b18 - Rename Java settings classes to <Name>Setting (#18171) (4 weeks ago) <Andrea Selva>
08db1d19f - Adds a required type tag to the open API spec of Logstash APIs. (#18169) (4 weeks ago) <Mashhur>
25c2551c8 - Release notes for 9.0.7 (#18158) (#18178) (4 weeks ago) <mergify[bot]>
b8bc4d8de - Move Port and PortRange Ruby settings to Java (#17964) (4 weeks ago) <Andrea Selva>
089361de5 - [main] (backport #18028) Release notes for 9.0.6 (#18173) (4 weeks ago) <mergify[bot]>
041e895c5 - Release notes for 9.1.3 (#18029) (#18174) (4 weeks ago) <mergify[bot]>
809ed0029 - Doc: Refine serverless and hosted content (#18166) (4 weeks ago) <Karen Metts>
feabee287 - (origin/mergify/bp/main/pr-18165) Doc: Add Logstash-to-serverless page (#18034) (4 weeks ago) <Karen Metts>
556366d87 - Fix race condition with version bump action (#18150) (5 weeks ago) <Cas Donoghue>
096f1a381 - Downgrade jruby to 9.4.13.0 (#18136) (5 weeks ago) <Cas Donoghue>
1e127fdda - Fix aarch64 acceptance tests (#18135) (5 weeks ago) <Cas Donoghue>
e16200a63 - Bump the github-actions group across 1 directory with 2 updates (#18133) (5 weeks ago) <dependabot[bot]>
6a51c82e4 - test: explicitly load ascii fixture as ascii, do line-oriented parsing (#18124) (6 weeks ago) <Rye Biesemeyer>
fe4a735c6 - Update JRuby version to 9.4.14.0 (#18080) (6 weeks ago) <João Duarte>
ba0787817 - pq: activate stringref extension for more-compact PQ representation (#17849) (6 weeks ago) <Rye Biesemeyer>
ef97a87d8 - Ensure any file object in a tar archive has an mtime (#18113) (6 weeks ago) <Cas Donoghue>
d2baf9fbc - github-actions: support backport labels after being merged (#18102) (6 weeks ago) <Victor Martinez>
d9b95bfd8 - Preserve mtime explicitly when creating tar artifacts (#18091) (6 weeks ago) <Cas Donoghue>
23d06e665 - Doc: Provide accurate post-geoip lookup example (#18092) (6 weeks ago) <Karen Metts>
5fb563473 - Fix gauge type correctly in pipelines metrics. (#18082) (6 weeks ago) <Mashhur>
f2621b00e - Ensure acceptance test artifacts are being built for correct arch (#18079) (6 weeks ago) <Cas Donoghue>
398a66cbe - upgrade golang to 1.25 (#18083) (6 weeks ago) <João Duarte>
386869a69 - make gradle files ready for gradle 10 (#17947) (6 weeks ago) <João Duarte>
895cfa5b1 - (origin/mergify/bp/main/pr-18077) Add Mergify rule for forwardporting documentation changes (#17874) (7 weeks ago) <Felipe Cotti>
e3055d14e - replace placeholder URLs (#18070) (7 weeks ago) <Colleen McGinnis>
f2e494843 - Build artifacts only for those that match host arch (#17995) (7 weeks ago) <Cas Donoghue>
e676b59ac - Start observabilitySRE container builds immediately on DRA (#18016) (7 weeks ago) <Cas Donoghue>
91a9527e5 - Stop waiting on ALL steps before staring junit annotation (#18049) (7 weeks ago) <Cas Donoghue>
ef41e83f7 - Add stub workflow file to iterate on (#17993) (7 weeks ago) <Cas Donoghue>
19d991416 - Split integration tests into more parts (#18036) (7 weeks ago) <Cas Donoghue>
5f7a6cdc1 - fixing thin and zero width white space characters in docs (#18019) (8 weeks ago) <George Wallace>
34a7c6769 - [DOCS] Fix nullable type linting error in OpenAPI document (#18018) (8 weeks ago) <Lisa Cawley>
75abd8a42 - [main] (backport #17781) Harmonize observability sre acceptance (#18001) (8 weeks ago) <mergify[bot]>
bc4645cee - adding x-metatags to openapi spec (#17854) (8 weeks ago) <George Wallace>
26027a1d8 - add pipeline id to thread context during init/start (#17944) (8 weeks ago) <Rye Biesemeyer>
50fc6458d - Bump actions/checkout in the github-actions group across 1 directory (#17996) (8 weeks ago) <dependabot[bot]>
7d4f476e6 - Update deploying-scaling-logstash.md (#17999) (#18002) (8 weeks ago) <mergify[bot]>
4512e57e6 - Put back the full start requirement which can be managed according to scenario requirement. (#17994) (9 weeks ago) <Mashhur>
74c7ec266 - [health-report CI] Print Logstash logs when pipeline faces an issue. (#17991) (9 weeks ago) <Mashhur>
22f6b69f4 - Preserve coerce behavior from Ruby impl (#17992) (9 weeks ago) <Cas Donoghue>
332355d68 - Start all exhastive tests in parallel (#17978) (9 weeks ago) <Cas Donoghue>
aed28eb32 - [docs] Add `applies_to` labels for 9.1.0 (#17864) (9 weeks ago) <Colleen McGinnis>
371d49537 - Remove release note (#17966) (#17972) (9 weeks ago) <Cas Donoghue>
64e64625e - Add fips config to jvm.options for observabilitySRE (#17958) (9 weeks ago) <Cas Donoghue>
fbb65ee34 - Include the prune filter for observabilitySRE image (#17957) (9 weeks ago) <Cas Donoghue>
aabf84ba4 - Convert Ruby Integer and PositiveInteger settings classes to Java (#17460) (9 weeks ago) <Andrea Selva>
5cad4367d - Replace reference to Elasticsearch Services with Elastic Cloud Hosted (#17946) (9 weeks ago) <Visha Angelova>
0b4360183 - Update source/target to Java17 (#17943) (10 weeks ago) <Rye Biesemeyer>
95a0466d8 - Move logstash release information to `.ci` (#17924) (10 weeks ago) <Cas Donoghue>
9b9790cd1 - pipeline logging: add cause chain when logging (#16677) (10 weeks ago) <Rye Biesemeyer>
90887906f - Update creating-logstash-pipeline.md (#17926) (#17927) (2 months ago) <mergify[bot]>
3b13df1d6 - cli: add hidden command-line flag for overriding settings (#17582) (2 months ago) <Rye Biesemeyer>
f164c2a5a - Release notes for 9.1.1 (#17914) (#17923) (2 months ago) <mergify[bot]>
1d565c0af - Removal of Ruby bridge classes for Gauge and Counter (#17858) (2 months ago) <Andrea Selva>
6b8d0903c - Log *what* components trigger a grype scan (#17905) (2 months ago) <Cas Donoghue>
97306065f - Update versions.yml (#17906) (2 months ago) <Andrea Selva>
f7dd12a59 - Removed agent field from collector, because not used (#17893) (2 months ago) <Andrea Selva>
a1a263bcf - Update release matrix based on 9.1.0 and 8.19.0 releases (#17868) (3 months ago) <Cas Donoghue>
bc7b74dd3 - [main] (backport #17875) Make sure FIPS comments belong in the platform-sre Dockerfile (#17898) (3 months ago) <mergify[bot]>
b430599c5 - make sure versions.yml is only read once into gradle.ext (#17865) (3 months ago) <João Duarte>
3565db81b - Update monkey patch for clamp to 1.3.3 (#17879) (3 months ago) <Cas Donoghue>
591437c94 - Standardization of FIPS Java config with ES (#17839) (3 months ago) <Cas Donoghue>
6d7d45ce3 - Fail pipeline when observabilitySRE fails to build (#17872) (3 months ago) <Cas Donoghue>
58af5e5bb - Release notes for 9.1.0 (#17822) (#17869) (3 months ago) <mergify[bot]>
882021815 - use centrally maintained version variables (#17857) (3 months ago) <Colleen McGinnis>
f1823d8fa - bump ci release version (#17844) (3 months ago) <kaisecheng>
caf91cf17 - Restore cgi pin (#17774) (3 months ago) <Cas Donoghue>
198adcf84 - [CI] fix benchmark docker name (#17827) (3 months ago) <kaisecheng>
f4c195ce6 - [CI] Remove UBI docker acceptance test (#17828) (3 months ago) <kaisecheng>
9583f0436 - Run tests with jruby 9.4.13.0 (#17798) (3 months ago) <Cas Donoghue>
207a69751 - Forwardport observability-sre internal distro support from 8.19 to main (#17785) (3 months ago) <Rye Biesemeyer>
521af3bd4 - Obsolete PQ setting queue.checkpoint.interval  (#17759) (3 months ago) <kaisecheng>
d03f2ce33 - Release notes for 9.0.4 (#17784) (#17818) (3 months ago) <mergify[bot]>
aaff3e91b - update commons-lang3 lib (#17812) (3 months ago) <kaisecheng>
95866a9fd - Pin jar-dependencies to match jruby 9.4.13.0 (#17787) (3 months ago) <Cas Donoghue>
9c5092d24 - update ubi9 ironbank base image to 9.6 (#17802) (3 months ago) <João Duarte>
8e73c680f - update dockerfile template based on feedback from dockerhub (#17794) (3 months ago) <João Duarte>
ddd519cc8 - pq: reduce read contention when caught up (#17765) (3 months ago) <Rye Biesemeyer>
95624abd9 - Fix allow_superuser comment (#17775) (3 months ago) <kaisecheng>
ba76f9414 - Bump the github-actions group across 1 directory with 3 updates (#17678) (3 months ago) <dependabot[bot]>
e9a3b7edb - Moved dependabot reviewers to codeowners (#17745) (3 months ago) <Olga Naydyonock>
9721b074c -  Update mergify with new 9.1 branch (#17740) (3 months ago) <Cas Donoghue>
d474b34e3 - mergify: remove duplicated config and use the default ones for the backport labels (#17742) (4 months ago) <Victor Martinez>
ed4022057 - Implement BufferedTokenizer to return an iterable that can verify size limit for every token emitted (#17229) (4 months ago) <Andrea Selva>
443e52728 - Fix deprecation warning with latest jruby/bundler (#17766) (4 months ago) <Cas Donoghue>
05da1bbc8 - Doc: Update getting started file to test publishing (#17762) (4 months ago) <Karen Metts>
5f54c0cc0 - Standardize image artifact name (#17727) (4 months ago) <kaisecheng>
b23882479 - Doc: Add clarification about API key format for Logstash (#17688) (4 months ago) <Visha Angelova>
792382765 - Bump to 9.2.0 for main (#17739) (4 months ago) <Cas Donoghue>

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