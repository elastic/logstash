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

## 9.5.0 [logstash-9.5.0-release-notes]

### Features and enhancements [logstash-9.5.0-features-enhancements]

---------- GENERATED CONTENT STARTS HERE ------------
=== Logstash Pull Requests with label v9.5.0

=== Logstash Commits between 9.5 and 9.4.4

Computed with "git log --pretty=format:'%h -%d %s (%cr) <%an>' --abbrev-commit --date=relative v9.4.4..9.5"

bb9d5f62a - (HEAD -> 9.5, origin/9.5) [9.5] (backport #19313) Release notes for 9.3.8 (#19325) (32 hours ago) <mergify[bot]>
94e5b9b5e - Release notes for 9.4.4 (#19314) (#19322) (32 hours ago) <mergify[bot]>
25f351689 - Bump actions/setup-node in the github-actions group across 1 directory (#19316) (#19318) (2 days ago) <mergify[bot]>
2e28f2373 - bump lock file for 9.5 (#19302) (8 days ago) <github-actions[bot]>
55cbe4404 - Track 9.next in .ci/logstash-versions.yml (#19301) (8 days ago) <Cas Donoghue>
a7c9e1ba4 - chore: deps(updatecli): Bump updatecli version to v0.119.0 (#19295) (#19297) (9 days ago) <mergify[bot]>
2e9b5b2aa - [9.5] (backport #19249) Bump jackson and jrjackson dependencies (#19287) (12 days ago) <mergify[bot]>
c563ec851 - Downgrade ES client (#19281) (2 weeks ago) <Cas Donoghue>
4a5541998 - [9.5 release] Create gemfile.lock from 9.4 (#19277) (2 weeks ago) <Álex Cámara Lara>
27841cfd1 - Update jruby to 10.0.6.0 (#19264) (2 weeks ago) <Cas Donoghue>
c2f03e0a0 - Bump docker/login-action in the github-actions group across 1 directory (#19269) (2 weeks ago) <dependabot[bot]>
0875e0b10 - Forwardporting 9.3.7 and 9.4.3 release notes to main (#19254) (3 weeks ago) <Mashhur>
9be3f33ea - Fix typos in pipeline.workers documentation (#19238) (4 weeks ago) <James Moon>
1576c0250 - Forwardport 9.3.6 to main (#19231) (4 weeks ago) <Mashhur>
c06b494eb - upgrade puma to 8.x (#19200) (4 weeks ago) <João Duarte>
2a031ac8f - deps: Bump ironbank version to 10.2 (#19218) (4 weeks ago) <github-actions[bot]>
6d894e856 - Bump actions/checkout in the github-actions group across 1 directory (#19217) (4 weeks ago) <dependabot[bot]>
7f7a61ca8 - ci: add team Slack mention to version bump pipeline notifications (#19202) (5 weeks ago) <ninalee12>
eacab559f - Bump OpenTelemetry to 1.62.0 (#19209) (5 weeks ago) <Kaise>
dcd46afa3 - ci: use copilot-requests: write instead of COPILOT_GITHUB_TOKEN PAT (5 weeks ago) <Victor Martinez>
421880d55 - document Logstash's file descriptors usage, limits and sizing guidance (#18584) (5 weeks ago) <João Duarte>
f2400df86 - chore: deps(updatecli): Bump updatecli version to v0.118.0 (#19203) (5 weeks ago) <github-actions[bot]>
ae40e7278 - Enable AI Agentic Workflow for Buildkite build failure analysis (#19196) (6 weeks ago) <Copilot>
04868fe4a - Fix flaky `FileWatchServiceTest` (#19184) (7 weeks ago) <Cas Donoghue>
497b995c7 - chore: deps(updatecli): Bump updatecli version to v0.117.1 (#19183) (7 weeks ago) <github-actions[bot]>
62f479ee6 - [Doc] Clarify API server TLS keystore auto-reload behavior (#19182) (8 weeks ago) <Kaise>
dc2b52321 - Forwardports 9.3.5 and 9.4.2 release notes. (#19176) (8 weeks ago) <Mashhur>
0b09a83ed - Add missed standard types during batch's size estimation (#19158) (8 weeks ago) <Andrea Selva>
c12cc9b9e - Bump the github-actions group across 1 directory with 2 updates (#19163) (8 weeks ago) <dependabot[bot]>
89ef160ec - Remove metrics OTLP dataset config option (#19142) (8 weeks ago) <Emily S>
f71e27b49 - Improve version bump flexibility and automate AWS deps updates to minor automatically while patching dependencies(#19118) (8 weeks ago) <Álex Cámara Lara>
45b237f37 - Create buildkite pipeline to periodically clean up logstash artifact snyk projects (#19139) (8 weeks ago) <Álex Cámara Lara>
9f842f511 - change team name (#19154) (9 weeks ago) <ninalee12>
c904f714c - Remove pipe output plugin from default bundle (#19159) (9 weeks ago) <Kaise>
d33fe7cc0 - Added known issue to version 9.2.0 for batch's estimate type errors (#19157) (9 weeks ago) <Andrea Selva>
849ad93f1 - Fix cgroup test isolation in otel_spec by resetting cached state (#19153) (9 weeks ago) <Emily S>
664798c06 - Make asciidoc RN generator org aware (#19145) (9 weeks ago) <Cas Donoghue>
7f72fb733 - Send Logstash Metrics via OTLP (#18857) (9 weeks ago) <Emily S>
76ca7e2c5 - Add RHEL 10, Oracle Linux 10, Rocky Linux 10, and Alma Linux 10 to exhaustive tests (#19123) (9 weeks ago) <Kaise>
0be31404c - chore: deps(updatecli): Bump updatecli version to v0.117.0 (#19128) (9 weeks ago) <github-actions[bot]>
a92145cdb - Remove cgi pin in Gemfile (#19119) (10 weeks ago) <Ivona Cvija>
ba5d2f108 - Upgrade jrjackson and fasterxml.jackson. (#19103) (10 weeks ago) <Mashhur>
582ea8823 - Remove legacy output concurrency (#19003) (10 weeks ago) <Andrew Cholakian>
d583fb7cc - Clear pipeline metrics when a pipeline fails to start (#19091) (10 weeks ago) <Kaise>
2821f4d18 - [Doc] Automatic reload of certificates (#19065) (2 months ago) <Kaise>
b898885aa - Release notes for 9.4.1 (#19096) (#19097) (2 months ago) <mergify[bot]>
7a575435f - Request to install JDK 21 in bump gems workflow (#19093) (3 months ago) <Andrea Selva>
f2f0d3fde - `dead_letter_queue.flush_check_interval` new config for flushing staled segment files. (#19036) (3 months ago) <Mashhur>
c39872426 - Extend TLS auto-reload to CPM and monitoring service clients (#19045) (3 months ago) <Kaise>
99e5f0684 - Release notes for 9.4.0 (#18973) (#19075) (3 months ago) <mergify[bot]>
7c0ca8a7a - Retry transient curl errors when checking JDK (#19073) (3 months ago) <Cas Donoghue>
6fca7c1ec - Bump tspascoal/get-user-teams-membership (#19067) (3 months ago) <dependabot[bot]>
ddb85d8a3 - Allow to pull elasticsearch 9.x ruby client versions. This provides an opportunity to upgrade the client in the ES plugins. (#19051) (3 months ago) <Mashhur>
f87d9c0c2 - Update bundled JDK to 21.0.11 build 10 (#19070) (3 months ago) <github-actions[bot]>
48b7601ba - Update getting-started-with-logstash min java version (#19058) (3 months ago) <Edmo Vamerlatti Costa>
a83f41cc6 - Release notes for 9.3.4 (#19042) (#19063) (3 months ago) <mergify[bot]>
74d9f5b56 - Exclude non-runtime dependencies for snyk scans of jar dependencies (#19039) (3 months ago) <Cas Donoghue>
89aeb16fe - chore: deps(updatecli): Bump updatecli version to v0.116.3 (#19047) (3 months ago) <github-actions[bot]>
91739d78f - Auto-reload pipelines on TLS certificate rotation (#18978) (3 months ago) <Kaise>
65a7b76f0 - Ensure do_close failures don't halt pipeline shutdown (#19035) (3 months ago) <Andrew Cholakian>
296f936dc - fix forced-shutdown (double SIGINT) behaviour for JRuby 10 (#19017) (3 months ago) <Rye Biesemeyer>
35a42f82b - Skip fips tests that invoke logstash keystore command (#19026) (3 months ago) <Cas Donoghue>
a63c5d484 - chore: deps(updatecli): Bump updatecli version to v0.116.2 (#19020) (3 months ago) <github-actions[bot]>
4a5172655 - require java 21, since jruby 10 requires it (#19010) (3 months ago) <Rye Biesemeyer>
894ca214c - Optimize DLQ segment directory scans with single-pass logic. (#18970) (3 months ago) <Mashhur>
3254ac755 - [9.3] Add deprecated JDK cipher to release notes (#18949) (#19007) (3 months ago) <mergify[bot]>
c3b4dca7d - Log the estimate of batch metrics memory consumption (#18916) (3 months ago) <Andrea Selva>
f7a42a53f - docs: clarify Gradle test task structure in AGENTS.md (#19004) (3 months ago) <Andrew Cholakian>
3c4fbaf4c - ci: enable use-release-branches for docs workflows (#18992) (3 months ago) <Martijn Laarman>
ce7ef0282 - log4j update to 2.25.4 (#18991) (3 months ago) <Rob Bavey>
3b0163ce5 - chore: deps(updatecli): Bump updatecli version to v0.116.1 (#18988) (3 months ago) <github-actions[bot]>
c4192aed2 - Bump actions/github-script (#18987) (3 months ago) <dependabot[bot]>
2ed80127e - Limit exhaustive test triggers to active branches only (#18975) (3 months ago) <Cas Donoghue>
597df17bc - pin multi_json to 1.19.1 since 1.20.0 has java variant with newer concurrent-ruby pin (#18977) (3 months ago) <João Duarte>
98760509e - add support for cgroupv2 (#18708) (3 months ago) <João Duarte>
82c33d7d1 - Expose ruby_plugin on filter/output delegators (#18936) (3 months ago) <Kaise>
f77ab48b6 - Update jruby to 10.0.5.0 (#18965) (3 months ago) <Cas Donoghue>
c50aa5582 - Bump logstash version 9.5.0 (#18957) (4 months ago) <github-actions[bot]>
af19ca630 - Support REACTIVE pipeline recovery with config.reload manager (#18930) (4 months ago) <Rye Biesemeyer>
8d7a5a31c - DeadLetterQueueUtils#extractSegmentId improvement: replace split with index of and substring methods. (#18874) (4 months ago) <Mashhur>

=== Logstash Plugin Release Changelogs ===
Computed from "git diff v9.4.4..9.5 *.release"
Changed plugin versions:
logstash-filter-elastic_integration: 9.4.5 -> 9.5.1
logstash-filter-elasticsearch: 4.3.1 -> 4.4.1
logstash-input-elasticsearch: 5.2.2 -> 5.3.2
logstash-integration-kafka: 11.8.10 -> 12.1.5
logstash-integration-snmp: 4.2.2 -> 4.3.1
logstash-output-pipe: 3.0.7 -> 3.0.7
logstash-output-udp: 3.2.0 -> 3.3.0
---------- GENERATED CONTENT ENDS HERE ------------

### Plugins [logstash-plugin-9.5.0-changes]

**Elastic_integration Filter - 9.5.1**

* Sync up with Elasticsearch 9.5 branch to pull latest dependencies [#476](https://github.com/elastic/logstash-filter-elastic_integration/pull/476)

* Fixes an issue where a field set by an integration pipeline to `java.util.Date` value-object representing a timestamp could not be converted to a timestamp [#460](https://github.com/elastic/logstash-filter-elastic_integration/issues/460)
* Applies Elasticsearch geoip module relocation changes [#445](https://github.com/elastic/logstash-filter-elastic_integration/pull/445)

* Include httpclient5/httpcore5 from the `elasticsearch-java` artifact [#458](https://github.com/elastic/logstash-filter-elastic_integration/pull/458)

* Upgrades `tools.jackson.core` dependency to 3.1.1 [#454](https://github.com/elastic/logstash-filter-elastic_integration/pull/454)

* Include Elasticsearch web-utils JAR into the plugin to keep `registered_domain` processor dependencies [#397](https://github.com/elastic/logstash-filter-elastic_integration/pull/397)
* Fixed `set_security_user` processor to behave consistently with other unsupported processors (`inference`, `enrich`) by tagging events with `_ingest_pipeline_failure` [#269](https://github.com/elastic/logstash-filter-elastic_integration/pull/269)
* Apply Elasticsearch user-agent plugin refactoring [#408](https://github.com/elastic/logstash-filter-elastic_integration/pull/408)

* Include httpclient5/httpcore5 from the `elasticsearch-java` artifact [#457](https://github.com/elastic/logstash-filter-elastic_integration/pull/457)

* Upgrades `tools.jackson.core` dependency to 3.1.1 [#453](https://github.com/elastic/logstash-filter-elastic_integration/pull/453)

* Upgrades `elasticsearch-java` and `elasticsearch-rest-client` dependencies to 9.latest [#418](https://github.com/elastic/logstash-filter-elastic_integration/pull/418)
* Upgrades transient `tools.jackson.core` dependency to 3.1.0

* Fixes the `MissingFormatArgumentException` potentially `String.format` may cause in the `SimpleResolverCache` [#393](https://github.com/elastic/logstash-filter-elastic_integration/pull/393)

* Embeds Ingest Node components from Elasticsearch 9.3 [#378](https://github.com/elastic/logstash-filter-elastic_integration/pull/378)

* Upgrades `elasticsearch-java` and `elasticsearch-rest-client` dependencies to 9.latest [#418](https://github.com/elastic/logstash-filter-elastic_integration/pull/418)
* Upgrades transient `tools.jackson.core` dependency to 3.1.0

* Fixes the `MissingFormatArgumentException` potentially `String.format` may cause in the `SimpleResolverCache` [#392](https://github.com/elastic/logstash-filter-elastic_integration/pull/392)

* Logging compatability with Elasticsearch 9.2 [#373](https://github.com/elastic/logstash-filter-elastic_integration/pull/373)
* Utilizes Elasticsearch interfaces via Elasticsearch logstash-bridge [#336](https://github.com/elastic/logstash-filter-elastic_integration/pull/336)

* Add `terminate` processor support [#345](https://github.com/elastic/logstash-filter-elastic_integration/pull/345)

* Introduces `proxy` param to support proxy [#316](https://github.com/elastic/logstash-filter-elastic_integration/pull/316)
* Embeds Ingest Node components from Elasticsearch 9.1

* Embeds Ingest Node components from Elasticsearch 9.0, no functional change [#291](https://github.com/elastic/logstash-filter-elastic_integration/pull/291)

* Pre-release for 9.0, no functional change [#265](https://github.com/elastic/logstash-filter-elastic_integration/pull/265)
* Embeds Ingest Node components from Elasticsearch 9.0.0 prerelease
* Compatible with Logstash 8.17+

* Aligns with stack major and minor versions, no functional changes [#285](https://github.com/elastic/logstash-filter-elastic_integration/pull/285)
* Embeds Ingest Node components from Elasticsearch 8.18

* Provides a guidance in logs when plugin version mismatches with connected Elasticsearch `major.minor` version [#255](https://github.com/elastic/logstash-filter-elastic_integration/pull/255)
* Embeds Ingest Node components from Elasticsearch 8.17
* Compatible with Logstash 8.15+

* Aligns with stack major and minor versions, no functional changes [#212](https://github.com/elastic/logstash-filter-elastic_integration/pull/212)
* Embeds Ingest Node components from Elasticsearch 8.17
* Compatible with Logstash 8.15+

* Provides a guidance in logs when plugin version mismatches with connected Elasticsearch `major.minor` version [#253](https://github.com/elastic/logstash-filter-elastic_integration/pull/253)
* Embeds Ingest Node components from Elasticsearch 8.16
* Compatible with Logstash 8.15+

* Aligns with stack major and minor versions, no functional changes [#210](https://github.com/elastic/logstash-filter-elastic_integration/pull/210)
* Embeds Ingest Node components from Elasticsearch 8.16
* Compatible with Logstash 8.15+

* Add `x-elastic-product-origin` header to Elasticsearch requests [#197](https://github.com/elastic/logstash-filter-elastic_integration/pull/197)

* Reflects the Elasticsearch GeoIP changes into the plugin and syncs with Elasticsearch 8.16 branch [#170](https://github.com/elastic/logstash-filter-elastic_integration/pull/170)

* Fixes the connection failure where SSL verification mode is disabled over SSL connection [#165](https://github.com/elastic/logstash-filter-elastic_integration/pull/165)

* Fix: register available PainlessExtension-s, resolving an issue where the pipelines for some integrations would fail to compile [#162](https://github.com/elastic/logstash-filter-elastic_integration/pull/162)

* Update default elasticsearch tree branch to 8.15 [#156](https://github.com/elastic/logstash-filter-elastic_integration/pull/156)

* Updates Elasticsearch Java client used[#155](https://github.com/elastic/logstash-filter-elastic_integration/pull/155)

* [DOC] Documents that integrations are designed to work best with data streams and ECS enabled [#153](https://github.com/elastic/logstash-filter-elastic_integration/pull/153)

* Fixes handling of array-type event fields by treating them as lists [#146](https://github.com/elastic/logstash-filter-elastic_integration/pull/146)
* Syncs with Elasticsearch 8.14, including support for new user-provided GeoIP database types `ConnectionType`, `Domain` and `Isp` [#147](https://github.com/elastic/logstash-filter-elastic_integration/pull/147)

* [DOC] Removes Tech Preview label and adds link to extending integrations topic in LSR [#142](https://github.com/elastic/logstash-filter-elastic_integration/pull/142)

* Fixes `EventProcessorBuilder#build` to work with JRuby 9.4.6.0 [#133](https://github.com/elastic/logstash-filter-elastic_integration/pull/133)

* Fixes `GeoIpDatabaseProvider.Builder#build` to work with JRuby 9.4.6.0 [#132](https://github.com/elastic/logstash-filter-elastic_integration/pull/132)

* Fixes issue where configured `username`/`password` credentials was not sent to Elasticsearch instances that had anonymous access enabled [#127](https://github.com/elastic/logstash-filter-elastic_integration/pull/127)

* Adds relevant information to Elasticsearch client's User-Agent header [#117](https://github.com/elastic/logstash-filter-elastic_integration/pull/117)

* Non-user facing work to shorten JAR path when packaging [#114](https://github.com/elastic/logstash-filter-elastic_integration/pull/114)

* [DOC] Additional links and formatting fixes to docs [#115](https://github.com/elastic/logstash-filter-elastic_integration/pull/115)

* Synchronize with Elasticsearch 8.12 and include elasticsearch-geo jar to include a missed class [#113](https://github.com/elastic/logstash-filter-elastic_integration/pull/113)

* Support non-encoded API Key [#101](https://github.com/elastic/logstash-filter-elastic_integration/pull/101)

* Re-syncs with Elasticsearch 8.11 [#91](https://github.com/elastic/logstash-filter-elastic_integration/pull/91)
* Adds support for `reroute` processor [#100](https://github.com/elastic/logstash-filter-elastic_integration/pull/100)
* Adds support for `geoip` processor to use databases from Logstash's Geoip Database Management service [#88](https://github.com/elastic/logstash-filter-elastic_integration/pull/88)
* Restores support for `redact` processor using its x-pack licensed implementation [#90](https://github.com/elastic/logstash-filter-elastic_integration/issues/90)

* Re-syncs with Elasticsearch 8.10 [#78](https://github.com/elastic/logstash-filter-elastic_integration/pull/78)
* BREAKING: The `redact` processor was removed from upstream IngestCommon, and therefore no longer available here.
* Documentation added for required privileges and unsupported processors [#72](https://github.com/elastic/logstash-filter-elastic_integration/pull/72)
* Added request header `Elastic-Api-Version` for serverless [#84](https://github.com/elastic/logstash-filter-elastic_integration/pull/84)

* Fixes several related issues with how fields are mapped from the Logstash Event to the IngestDocument and back again [#51](https://github.com/elastic/logstash-filter-elastic_integration/pull/51)
* `IngestDocument` metadata fields are now separately routed to `[@metadata][_ingest_document]` on the resulting `Event`, fixing an issue where the presence of Elasticsearch-reserved fields such as the top-level `_version` would cause a downstream Elasticsearch output to be unable to index the event [#47][]
* Top-level `@timestamp` and `@version` fields are no longer excluded from the `IngestDocument`, as required by some existing integration pipelines [#54][]
* Field-type conversions have been improved by presenting logstash `Timestamp`-type objects as their ISO8601-encoded `String`s mapping any returned `ZonedDateTime`-objects into logstash `Timestamp`s to support several Ingest Common processors and their typical use in Elastic Integration pipelines [#65][], [#70][]
* Adds proactive reloaders for both datastream-to-pipeline-name mappings and pipeline definitions to ensure upstream changes are made available without impacting processing [#48](https://github.com/elastic/logstash-filter-elastic_integration/pull/48)
* Presents helpful guidance when run on an unsupported version of Java [#43](https://github.com/elastic/logstash-filter-elastic_integration/pull/43)
* Fix: now plugin is able to establish a connection to Elasticsearch on Elastic cloud with `cloud_id` and `cloud_auth` authentication pair [#62](https://github.com/elastic/logstash-filter-elastic_integration/pull/62)
* Adds `pipeline_name` to _override_ the default behaviour of auto-detecting the pipeline name from its data stream [#69](https://github.com/elastic/logstash-filter-elastic_integration/pull/69)
* BREAKING: http basic authentication with Elasticsearch is now configured with `username` and `password` options to make this plugin behave more similarly to other Elasticsearch-related plugins [#61](https://github.com/elastic/logstash-filter-elastic_integration/pull/61)
* Improves user-experience when connected to an Elasticsearch that does not have security features enabled (such as when testing against an on-prem cluster) [#64](https://github.com/elastic/logstash-filter-elastic_integration/pull/64)
* Provides helpful guidance when providing request credentials to an unsecured Elasticsearch cluster. 
* Tolerates anonymous access of an unsecured Elasticsearch cluster by allowing the plugin to start in an "unsafe" mode without pre-validating permission to use the necessary Elasticsearch APIs.

[#47]: https://github.com/elastic/logstash-filter-elastic_integration/issues/47
[#54]: https://github.com/elastic/logstash-filter-elastic_integration/issues/54
[#65]: https://github.com/elastic/logstash-filter-elastic_integration/issues/65
[#70]: https://github.com/elastic/logstash-filter-elastic_integration/issues/70

* Empty Bootstrap of Logstash filter plugin [#1](https://github.com/logstash-plugins/logstash-filter-elastic_integration/pull/1)
* Adds basic configuration options required for Elasticsearch connection [#2](https://github.com/logstash-plugins/logstash-filter-elastic_integration/pull/2)

**Elasticsearch Filter - 4.4.1**

* Support Elastic Cloud API keys in the `api_key` option, which now accepts an `id:api_key` pair, its base64-encoded form, or an `essu_` Cloud API key, and rejects an unrecognized format at startup [#215](https://github.com/logstash-plugins/logstash-filter-elasticsearch/pull/215)

* Drop a support for Logstash 7.x by requiring `elasticsearch` gem >= 8. Logstash 8+ continues to work as before. [#213](https://github.com/logstash-plugins/logstash-filter-elasticsearch/pull/213)

**Elasticsearch Input - 5.3.2**

* Support Elastic Cloud API keys in the `api_key` option, which now accepts an `id:api_key` pair, its base64-encoded form, or an `essu_` Cloud API key, and rejects an unrecognized format at startup [#274](https://github.com/logstash-plugins/logstash-input-elasticsearch/pull/274)

* Fix serverless request failure caused by conflicting `compatible-with` and `Elastic-Api-Version` headers when using elasticsearch-ruby v9 [#269](https://github.com/logstash-plugins/logstash-input-elasticsearch/pull/269)

* Drop a support for Logstash 7.x by requiring elasticsearch gem >= 8. Logstash 8+ continues to work as before [#252](https://github.com/logstash-plugins/logstash-input-elasticsearch/pull/252)

**Kafka Integration - 12.1.5**

* Upgrades `httpcore5` dependency to v5.4.2 [#270](https://github.com/logstash-plugins/logstash-integration-kafka/pull/270)

* Update jackson dependency to 2.21.4 [#268](https://github.com/logstash-plugins/logstash-integration-kafka/pull/268)

* Upgrades `httpcore5` dependency to v5.3.6 [#262](https://github.com/logstash-plugins/logstash-integration-kafka/pull/262)

* Upgrade `com.fasterxml.jackson` dependencies to 2.21.2 [#254](https://github.com/logstash-plugins/logstash-integration-kafka/pull/254)

* Fix `sasl_jaas_config` output configuration [#245](https://github.com/logstash-plugins/logstash-integration-kafka/pull/245)

* Update Kafka client to 4.2.0 [#243](https://github.com/logstash-plugins/logstash-integration-kafka/pull/243)
* Remove explicit `lz4-java` dependency (now transitive from Kafka client)
* Document `by_duration` offset reset strategy (available since Apache Kafka 4.0.0)

* [DOC] Add info about Kafka timestamp behavior [#240](https://github.com/logstash-plugins/logstash-integration-kafka/pull/240)

* Redact `sasl_jaas_config` to prevent credentials from appearing in debug logs. [#232](https://github.com/logstash-plugins/logstash-integration-kafka/pull/232)

* Re-packaging the plugin [#221](https://github.com/logstash-plugins/logstash-integration-kafka/pull/221)

* Upgrade `kafka-avro-serializer` dependency [#215](https://github.com/logstash-plugins/logstash-integration-kafka/pull/215)

* Upgrade lz4 dependency [#212](https://github.com/logstash-plugins/logstash-integration-kafka/pull/212)

* Remove duplicated deprecation log entry [#208](https://github.com/logstash-plugins/logstash-integration-kafka/pull/208)

* Update kafka client to 4.1.0 and transitive dependencies [#205](https://github.com/logstash-plugins/logstash-integration-kafka/pull/205)
* Breaking Change: partitioner options `default` and `uniform_sticky` are removed
* `linger_ms` default value changed from 0 to 5
* Add `group_protocols` options for configuring Kafka consumer rebalance protocol
* Setting `group_protocol => consumer` opts in to the new consumer group protocol

* Add `reconnect_backoff_max_ms` option for configuring kafka client [#204](https://github.com/logstash-plugins/logstash-integration-kafka/pull/204)

* Display exception chain comes from kafka client [#200](https://github.com/logstash-plugins/logstash-integration-kafka/pull/200)

* Update kafka client to 3.9.1 and transitive dependencies [#193](https://github.com/logstash-plugins/logstash-integration-kafka/pull/193)

* Docs: fixed setting type reference for `sasl_iam_jar_paths` [#192](https://github.com/logstash-plugins/logstash-integration-kafka/pull/192)   

* Expose the SASL client callback class setting to the Logstash configuration [#177](https://github.com/logstash-plugins/logstash-integration-kafka/pull/177)
* Adds a mechanism to load AWS IAM authentication as SASL client libraries at startup [#178](https://github.com/logstash-plugins/logstash-integration-kafka/pull/178)

* Support additional `oauth` and `sasl` configuration options for configuring kafka client [#189](https://github.com/logstash-plugins/logstash-integration-kafka/pull/189)

* Update kafka client to 3.8.1 and transitive dependencies [#188](https://github.com/logstash-plugins/logstash-integration-kafka/pull/188)
* Removed Jar Dependencies dependency [#187](https://github.com/logstash-plugins/logstash-integration-kafka/pull/187)

* Update kafka client to 3.7.1 and transitive dependencies [#186](https://github.com/logstash-plugins/logstash-integration-kafka/pull/186)

* Update avro to 1.11.4 and confluent kafka to 7.4.7 [#184](https://github.com/logstash-plugins/logstash-integration-kafka/pull/184)

* Specify that only headers with UTF-8 encoded values are supported in extended decoration [#174](https://github.com/logstash-plugins/logstash-integration-kafka/pull/174)

* Add "auto_create_topics" option to allow disabling of topic auto creation [#172](https://github.com/logstash-plugins/logstash-integration-kafka/pull/172)

* Add default client_id of logstash to kafka output [#169](https://github.com/logstash-plugins/logstash-integration-kafka/pull/169)

* [DOC] Match anchor ID and references for `message_headers` [#164](https://github.com/logstash-plugins/logstash-integration-kafka/pull/164)

* Add support for setting Kafka message headers in output plugin [#162](https://github.com/logstash-plugins/logstash-integration-kafka/pull/162)

* Fix "retries" and "value_serializer" error handling in output plugin (#160) [#160](https://github.com/logstash-plugins/logstash-integration-kafka/pull/160)

* Fix "Can't modify frozen string" error when record value is `nil` (tombstones) [#155](https://github.com/logstash-plugins/logstash-integration-kafka/pull/155)

* Fix: update Avro library [#150](https://github.com/logstash-plugins/logstash-integration-kafka/pull/150)

* Fix: update snappy dependency [#148](https://github.com/logstash-plugins/logstash-integration-kafka/pull/148)

* Bump kafka client to 3.4.1 [#145](https://github.com/logstash-plugins/logstash-integration-kafka/pull/145)

* Fix nil exception to empty headers of record during event metadata assignment [#140](https://github.com/logstash-plugins/logstash-integration-kafka/pull/140)

* Added TLS truststore and keystore settings specifically to access the schema registry [#137](https://github.com/logstash-plugins/logstash-integration-kafka/pull/137)

* Added config `group_instance_id` to use the Kafka's consumer static membership feature [#135](https://github.com/logstash-plugins/logstash-integration-kafka/pull/135)

* Changed Kafka client to 3.3.1, requires Logstash >= 8.3.0. 
* Deprecated `default` value for setting `client_dns_lookup` forcing to `use_all_dns_ips` when explicitly used [#130](https://github.com/logstash-plugins/logstash-integration-kafka/pull/130)
* Changed the consumer's poll from using the one that blocks on metadata retrieval to the one that doesn't [#136](https://github.com/logstash-plugins/logstash-integration-kafka/pull/133)

* Fix: update Avro library on 10.x [#149](https://github.com/logstash-plugins/logstash-integration-kafka/pull/149)

* bump kafka client to 2.8.1 [#115](https://github.com/logstash-plugins/logstash-integration-kafka/pull/115)

* Feat: added connections_max_idle_ms setting for output [#118](https://github.com/logstash-plugins/logstash-integration-kafka/pull/118)
* Refactor: mixins to follow shared mixin module naming

* Update CHANGELOG.md [#114](https://github.com/logstash-plugins/logstash-integration-kafka/pull/114)

* Added config setting to enable 'zstd' compression in the Kafka output [#112](https://github.com/logstash-plugins/logstash-integration-kafka/pull/112)

* Refactor: leverage codec when using schema registry [#106](https://github.com/logstash-plugins/logstash-integration-kafka/pull/106)
    Previously using `schema_registry_url` parsed the payload as JSON even if `codec => 'plain'` was set, this is no longer the case.  

* [DOC] Updates description of `enable_auto_commit=false` to clarify that the commit happens after data is fetched AND written to the queue [#90](https://github.com/logstash-plugins/logstash-integration-kafka/pull/90)
* Fix: update to Gradle 7 [#104](https://github.com/logstash-plugins/logstash-integration-kafka/pull/104)
* [DOC] Clarify Kafka client does not support proxy [#103](https://github.com/logstash-plugins/logstash-integration-kafka/pull/103)

* [DOC] Removed a setting recommendation that is no longer applicable for Kafka 2.0+ [#99](https://github.com/logstash-plugins/logstash-integration-kafka/pull/99)

* Added config setting to enable schema registry validation to be skipped when an authentication scheme unsupported
    by the validator is used [#97](https://github.com/logstash-plugins/logstash-integration-kafka/pull/97)

* Fix: Correct the settings to allow basic auth to work properly, either by setting `schema_registry_key/secret` or embedding username/password in the
    url [#94](https://github.com/logstash-plugins/logstash-integration-kafka/pull/94)

* Test: specify development dependency version [#91](https://github.com/logstash-plugins/logstash-integration-kafka/pull/91)

* Improved error handling in the input plugin to avoid errors 'escaping' from the plugin, and crashing the logstash
    process [#87](https://github.com/logstash-plugins/logstash-integration-kafka/pull/87)

* Docs: make sure Kafka clients version is updated in docs [#83](https://github.com/logstash-plugins/logstash-integration-kafka/pull/83)
    Since **10.6.0** Kafka client was updated to **2.5.1**

* Changed `decorate_events` to add also Kafka headers [#78](https://github.com/logstash-plugins/logstash-integration-kafka/pull/78)

* Update Jersey dependency to version 2.33 [#75](https://github.com/logstash-plugins/logstash-integration-kafka/pull/75)

* Fix: dropped usage of SHUTDOWN event deprecated since Logstash 5.0 [#71](https://github.com/logstash-plugins/logstash-integration-kafka/pull/71)
  
* Switched use from Faraday to Manticore as HTTP client library to access Schema Registry service 
    to fix issue [#63](https://github.com/logstash-plugins/logstash-integration-kafka/pull/63) 

* Added functionality to Kafka input to use Avro deserializer in retrieving data from Kafka. The schema is retrieved
    from an instance of Confluent's Schema Registry service [#51](https://github.com/logstash-plugins/logstash-integration-kafka/pull/51)
     
* Fix: set (optional) truststore when endpoint id check disabled [#60](https://github.com/logstash-plugins/logstash-integration-kafka/pull/60).
    Since **10.1.0** disabling server host-name verification (`ssl_endpoint_identification_algorithm => ""`) did not allow 
    the (output) plugin to set `ssl_truststore_location => "..."`.

* Docs: explain group_id in case of multiple inputs [#59](https://github.com/logstash-plugins/logstash-integration-kafka/pull/59)

* [DOC]Replaced plugin_header file with plugin_header-integration file. [#46](https://github.com/logstash-plugins/logstash-integration-kafka/pull/46)
* [DOC]Update kafka client version across kafka integration docs [#47](https://github.com/logstash-plugins/logstash-integration-kafka/pull/47)
* [DOC]Replace hard-coded kafka client and doc path version numbers with attributes to simplify doc maintenance [#48](https://github.com/logstash-plugins/logstash-integration-kafka/pull/48)  

* Changed: retry sending messages only for retriable exceptions [#27](https://github.com/logstash-plugins/logstash-integration-kafka/pull/29)

* [DOC] Fixed formatting issues and made minor content edits [#43](https://github.com/logstash-plugins/logstash-integration-kafka/pull/43)

* added the input `isolation_level` to allow fine control of whether to return transactional messages [#44](https://github.com/logstash-plugins/logstash-integration-kafka/pull/44)

* added the input and output `client_dns_lookup` parameter to allow control of how DNS requests are made [#28](https://github.com/logstash-plugins/logstash-integration-kafka/pull/28)

* Changed: config defaults to be aligned with Kafka client defaults [#30](https://github.com/logstash-plugins/logstash-integration-kafka/pull/30)

* updated kafka client (and its dependencies) to version 2.4.1 ([#16](https://github.com/logstash-plugins/logstash-integration-kafka/pull/16))
* added the input `client_rack` parameter to enable support for follower fetching
* added the output `partitioner` parameter for tuning partitioning strategy
* Refactor: normalized error logging a bit - make sure exception type is logged
* Fix: properly handle empty ssl_endpoint_identification_algorithm [#8](https://github.com/logstash-plugins/logstash-integration-kafka/pull/8)
* Refactor : made `partition_assignment_strategy` option easier to configure by accepting simple values from an enumerated set instead of requiring lengthy class paths ([#25](https://github.com/logstash-plugins/logstash-integration-kafka/pull/25))

* Fix links in changelog pointing to stand-alone plugin changelogs.
* Refactor: scope java_import to plugin class

* Initial release of the Kafka Integration Plugin, which combines
    previously-separate Kafka plugins and shared dependencies into a single
    codebase; independent changelogs for previous versions can be found:
* [Kafka Input Plugin @9.1.0](https://github.com/logstash-plugins/logstash-input-kafka/blob/v9.1.0/CHANGELOG.md)
* [Kafka Output Plugin @8.1.0](https://github.com/logstash-plugins/logstash-output-kafka/blob/v8.1.0/CHANGELOG.md)

**Snmp Integration - 4.3.1**

* Fix: generate error events with _snmpfailure tag when all SNMP operations fail and the response data is empty (e.g., timeout) [#92](https://github.com/logstash-plugins/logstash-integration-snmp/pull/92)

* Handle partial responses and errors gracefully: add `tag_on_failure` (default: `["_snmpfailure"]`) to tag events when SNMP operations fail, and `allow_partial_response` (default: `false`) to preserve partial data from failed `walk`/`table` operations [#91](https://github.com/logstash-plugins/logstash-integration-snmp/pull/91)

**Pipe Output - 3.0.7**

**Udp Output - 3.3.0**

* Added support for IPv6 addresses [#16](https://github.com/logstash-plugins/logstash-output-udp/pull/16)


## 9.4.4 [logstash-9.4.4-release-notes]

### Updates to dependencies [logstash-9.4.4-dependencies]

* Updated JRuby to 10.0.6.0 [#19279](https://github.com/elastic/logstash/pull/19279)
* Updated Jackson and jrjackson dependencies [#19286](https://github.com/elastic/logstash/pull/19286)
* Upgraded Puma to 8.x [#19234](https://github.com/elastic/logstash/pull/19234)

### Plugins [logstash-plugin-9.4.4-changes]

**Elastic_integration Filter - 9.4.5**

* Sync up with Elasticsearch 9.4 branch to pull latest dependencies [#477](https://github.com/elastic/logstash-filter-elastic_integration/pull/477)

* Update jackson dependency to 3.1.4 [#467](https://github.com/elastic/logstash-filter-elastic_integration/pull/467)

**Azure_event_hubs Input - 1.5.8**

* Update jackson dependency to 2.21.4 [#118](https://github.com/logstash-plugins/logstash-input-azure_event_hubs/pull/118)

**Beats Input - 7.0.12**

* When configured to use a port that is already in use, the failure is now propagated to the pipeline [#537](https://github.com/logstash-plugins/logstash-input-beats/pull/537)
    This fixes an issue where a misconfigured input could retry indefinitely while Logstash's health report continued to report the pipeline as healthy.

**Http Input - 4.1.11**

* When configured to use a port that is already in use, the failure is now propagated to the pipeline [#221](https://github.com/logstash-plugins/logstash-input-http/pull/221)
    This fixes an issue where a misconfigured input could retry indefinitely while Logstash's health report continued to report the pipeline as healthy.

**Kafka Integration - 11.8.10**

* Update jackson dependency to 2.21.4 [#269](https://github.com/logstash-plugins/logstash-integration-kafka/pull/269)

**Elasticsearch Output - 12.1.6**

* Fix serverless compatibility: nil params in pool requests and unsupported template settings [#1276](https://github.com/logstash-plugins/logstash-output-elasticsearch/pull/1276)

* Support Elastic Cloud API keys in the `api_key` option, which now accepts an `id:api_key` pair, its base64-encoded form, or an `essu_` Cloud API key, and rejects an unrecognized format at startup [#1274](https://github.com/logstash-plugins/logstash-output-elasticsearch/pull/1274)

* [Doc] Add note for index option [#1269](https://github.com/logstash-plugins/logstash-output-elasticsearch/pull/1269)


## 9.4.3 [logstash-9.4.3-release-notes]

### Features and enhancements [logstash-9.4.3-features-enhancements]

* Batch size estimation improvements [#19180](https://github.com/elastic/logstash/pull/19180)

### Updates to documentations [logstash-9.4.3-documentations]

* Logstash's file descriptors usage, limits and sizing guidance documented [#19206](https://github.com/elastic/logstash/pull/19206)

### Plugins [logstash-plugin-9.4.3-changes]

**Azure_event_hubs Input - 1.5.7**

* Upgrades `jackson.core` to 2.21.2 and `nimbus-jose-jwt` to 10.9 versions. [#117](https://github.com/logstash-plugins/logstash-input-azure_event_hubs/pull/117)

* [DOCS] Added recommendation to migrate to the Kafka integration plugin [#116](https://github.com/logstash-plugins/logstash-input-azure_event_hubs/pull/116)

**Beats Input - 7.0.11**

* Update Netty dependency to 4.1.135.Final [#567](https://github.com/logstash-plugins/logstash-input-beats/pull/567)

**Http Input - 4.1.10**

* Update Netty dependency to 4.1.135.Final [#219](https://github.com/logstash-plugins/logstash-input-http/pull/219)

**Tcp Input - 7.0.11**

* Update Netty dependency to 4.1.135.Final [#274](https://github.com/logstash-plugins/logstash-input-tcp/pull/274)

## 9.4.2 [logstash-9.4.2-release-notes]

### Fixes [logstash-9.4.2-fixes]

* Fixes a metric leak in `_node/stats` when a pipeline repeatedly fails to start with `config.reload.automatic: true`. Previously, each retry left a fresh set of plugin metric entries in the collector, causing the stats payload to grow indefinitely [#19120](https://github.com/elastic/logstash/pull/19120)

### Updates to dependencies [logstash-9.4.2-dependencies]

* Updated jruby-openssl to 0.16.0 [#19116](https://github.com/elastic/logstash/pull/19116)
* Upgraded jrjackson and fasterxml.jackson [#19126](https://github.com/elastic/logstash/pull/19126)

### Plugins [logstash-plugin-9.4.2-changes]

**Elastic_integration Filter - 9.4.3**

* Fixes an issue where a field set by an integration pipeline to `java.util.Date` value-object representing a timestamp could not be converted to a timestamp [#462](https://github.com/elastic/logstash-filter-elastic_integration/issues/462)

* Include httpclient5/httpcore5 from the `elasticsearch-java` artifact [#458](https://github.com/elastic/logstash-filter-elastic_integration/pull/458)

**Kafka Integration - 11.8.9**

* Upgrades jackson.core to 2.21.2 version [#255](https://github.com/logstash-plugins/logstash-integration-kafka/pull/255)

**Beats Input - 7.0.10**

* Update Netty dependency to 4.1.134.Final [#541](https://github.com/logstash-plugins/logstash-input-beats/pull/541)

**Http Input - 4.1.9**

* Update Netty dependency to 4.1.134.Final [#217](https://github.com/logstash-plugins/logstash-input-http/pull/217)

**Tcp Input - 7.0.10**

* Update Netty dependency to 4.1.134.Final [#257](https://github.com/logstash-plugins/logstash-input-tcp/pull/257)

**Pipe Output - 3.0.7**

* [DOC] Document `command` string form limitation [#6](https://github.com/logstash-plugins/logstash-output-pipe/pull/6)


## 9.4.1 [logstash-9.4.1-release-notes]

### Features and enhancements [logstash-9.4.1-features-enhancements]

#### Dead letter queue flush check interval [logstash-9.4.1-dlq-flush-check-interval]

Introduces new `dead_letter_queue.flush_check_interval` config for flushing the staled segment files scheduler 
which can reduce frequent check overhead.
If you are using intensive DLQ operations (write/read), the frequent flush check scheduler might create more overhead for the pipeline, increasing CPU usage. 
Introducing configurable scheduler cadence improves the pipeline efficiency by removing frequent operations 
[#19036](https://github.com/elastic/logstash/pull/19036).

### Updates to dependencies [logstash-9.4.1-dependencies]

* Update bundled JDK to 21.0.11 build 10.

### Plugins [logstash-plugin-9.4.1-changes]

**Beats Input - 7.0.9**

* Update Netty dependency to 4.1.133.Final [#539](https://github.com/logstash-plugins/logstash-input-beats/pull/539)

**Http Input - 4.1.8**

* Update Netty dependency to 4.1.133.Final [#216](https://github.com/logstash-plugins/logstash-input-http/pull/216)

**Tcp Input - 7.0.9**

* Update Netty dependency to 4.1.133.Final [#256](https://github.com/logstash-plugins/logstash-input-tcp/pull/256)

* When configured to use a port that is already in use, the failure is now propagated to the pipeline.
  This fixes an issue where a misconfigured input could retry indefinitely while Logstash's health report continued to report the pipeline as healthy [#250](https://github.com/logstash-plugins/logstash-input-tcp/pull/250)

**Elasticsearch Output - 12.1.3**

* Improves the logging experience when DLQ used [#1253](https://github.com/logstash-plugins/logstash-output-elasticsearch/pull/1253).


## 9.4.0 [logstash-9.4.0-release-notes]

### Features and enhancements [logstash-9.4.0-features-enhancements]

#### Reactive pipeline recovery [logstash-9.4.0-reactive-pipeline-recovery]

This release adds a feature to recover from pipeline crashes, under the setting `pipeline.recovery` [#18930](https://github.com/elastic/logstash/pull/18930).
Crash recovery is applied when `config.reload.automatic` is enabled and accepts:

* `auto`: enables pipeline crash recovery for pipelines backed by the persistent queue
* `false` (default): do not automate recovery of crashed pipelines
* `true`: enables pipeline crash recovery for any pipeline, even if backed by the ephemeral memory queue (risk: data loss)

#### Batch chunking  [logstash-9.4.0-batch-chunking]

We have added a safety mechanism to limit memory expansion when using filters that produce more events than they consume (like the `split` filter), controlled by the new `pipeline.batch.output_chunking.growth_threshold_factor` setting [#18680](https://github.com/elastic/logstash/pull/18680). 
When a batch growth exceeds the configured factor, it is re-chunked into smaller batches of `pipeline.batch.size` events before being handled by the outputs.

#### New batch histogram metrics [logstash-9.4.0-new-batch-histogram-metrics]

We've improved visibility of batch sizing at a pipeline level by exposing new histogram-type metrics in the `GET /_node/stats` endpoint [#17838](https://github.com/elastic/logstash/issues/17838). 
These metrics show the distribution of batch sizes in bytes and event-count for the lifetime of the pipeline, as well as for the most recent 1, 5, and 15-minute time windows.

#### Additional features and enhancements [logstash-9.4.0-more-features]

* Performance improvements which saves ~40% CPU resource on DLQ segment file lookup operations [19013](https://github.com/elastic/logstash/pull/19013)

### Updates to dependencies [logstash-9.4.0-dependencies]

* Update JRuby to 10.0.5.0
* Update bundled JDK to 21.0.10 build 7

::::{important}

Logstash 9.4.0 upgrades JRuby to 10 because 9.x is now EOL. JRuby 10 requires Java 21, dropping support for any version below, including 17.
For this reason, Logstash now also requires Java 21 or later, and Java 17 is no longer supported.

As of JDK 21.0.10, all `TLS_RSA_*` cipher suites are deactivated by default due to their lack of forward secrecy. Connections relying on these suites will fail with an `SSLHandshakeException` and must be migrated to ECDHE-based cipher suites.

::::

### Plugins [logstash-plugin-9.4.0-changes]

::::{important}

The Kafka Integration plugin `11.x` has been deprecated. The next minor Logstash release will bundle Kafka integration plugin `12.x` in its place, which introduces breaking changes, read more about them in the [CHANGELOG.md](https://github.com/logstash-plugins/logstash-integration-kafka/blob/v12.0.0/CHANGELOG.md#1200)

::::

**Aggregate Filter - 2.11.0**

* Feature: Add a warning log message when the number of tasks stored in memory exceeds the configured threshold [#125](https://github.com/logstash-plugins/logstash-filter-aggregate/issues/125)

**Aws Integration - 7.3.4**

* Use milliseconds timestamp precision in S3 input to fix the skip backup and delete object issue in S3-compatible storage services [#60](https://github.com/logstash-plugins/logstash-integration-aws/pull/60)
* Replace deprecated `Aws::S3::Object#upload_file` in favor of `Aws::S3::TransferManager#upload_file` [#67](https://github.com/logstash-plugins/logstash-integration-aws/pull/67)
* Replace deprecated `File.exists?` with `File.exist?` for Ruby 3.4 (JRuby 10) compatibility [#65](https://github.com/logstash-plugins/logstash-integration-aws/pull/65)
* Re-packaging the plugin [#63](https://github.com/logstash-plugins/logstash-integration-aws/pull/63)
* Add `cutoff_second configuration` option to S3 input plugin [#59](https://github.com/logstash-plugins/logstash-integration-aws/pull/59)

**Date Filter - 3.2.0**

* Add `precision` setting to support nanosecond precision timestamps [#165](https://github.com/logstash-plugins/logstash-filter-date/pull/165)
  * `ms` (default): timestamps are stored with millisecond precision
    * it keeps the same behavior as before for backward compatibility
    * fractional seconds are truncated to 3 digits
    * custom parsing formats use `joda-time` library
  * `ns`: timestamps are stored with nanosecond precision
    * fractional seconds support up to 9 digits
    * custom parsing formats use `java.time`
* `ISO8601` now accepts up to 9 fractional-second digits

**De_dot Filter - 1.2.0**

* Apply an 'error' tag to any event that fails the de-dotting process [#26](https://github.com/logstash-plugins/logstash-filter-de_dot/pull/26)

**Dissect Filter - 1.3.0**

* Add JRuby 10 support: replace removed `NativeException` with `RaiseException`, source JRuby from Logstash vendor directory instead of pinning Maven version [#96](https://github.com/logstash-plugins/logstash-filter-dissect/pull/96)

**Elastic Integration Filter - 9.4.0**

* Include Elasticsearch web-utils JAR into the plugin to keep `registered_domain` processor dependencies [#397](https://github.com/elastic/logstash-filter-elastic_integration/pull/397)
* Fixed `set_security_user` processor to behave consistently with other unsupported processors (`inference`, `enrich`) by tagging events with `_ingest_pipeline_failure` [#269](https://github.com/elastic/logstash-filter-elastic_integration/pull/269)

**Fingerprint Filter - 3.5.0**

* Fix fingerprint instability for Hash and Array field values caused by JRuby 10 changing `Hash#inspect` formatting [#79](https://github.com/logstash-plugins/logstash-filter-fingerprint/pull/79)

**Kafka Integration - 11.8.8**

* Fix a regression introduced in `11.8.7` where `sasl_jaas_config` was incorrectly typed in the output plugin, crashing Logstash on startup when a SASL Kafka output configuration was present [#247](https://github.com/logstash-plugins/logstash-integration-kafka/pull/247)
  
**Mutate Filter - 3.6.0**

* Add JRuby 10 support: fix integer conversion precision loss beyond 2^53 caused by `parse_signed_hex_str` routing all strings through `Float()` [#178](https://github.com/logstash-plugins/logstash-filter-mutate/pull/178)

**Gelf Input - 3.4.0**

* Updates the `gelf` dependency [#77](https://github.com/logstash-plugins/logstash-input-gelf/pull/77)

## 9.3.8 [logstash-9.3.8-release-notes]

### Updates to dependencies [logstash-9.3.8-dependencies]

* Updated JRuby to 9.4.15.0 [#19290](https://github.com/elastic/logstash/pull/19290)
* Updated Jackson and jrjackson dependencies [#19289](https://github.com/elastic/logstash/pull/19289)

### Plugins [logstash-plugin-9.3.8-changes]

**Elastic_integration Filter - 9.3.7**

* Sync up with Elasticsearch 9.3 branch to pull latest dependencies [#478](https://github.com/elastic/logstash-filter-elastic_integration/pull/478)

* Update jackson dependency to 3.1.4 [#470](https://github.com/elastic/logstash-filter-elastic_integration/pull/470)

**Azure_event_hubs Input - 1.5.8**

* Update jackson dependency to 2.21.4 [#118](https://github.com/logstash-plugins/logstash-input-azure_event_hubs/pull/118)

**Beats Input - 7.0.12**

* When configured to use a port that is already in use, the failure is now propagated to the pipeline [#537](https://github.com/logstash-plugins/logstash-input-beats/pull/537)
    This fixes an issue where a misconfigured input could retry indefinitely while Logstash's health report continued to report the pipeline as healthy.

**Http Input - 4.1.11**

* When configured to use a port that is already in use, the failure is now propagated to the pipeline [#221](https://github.com/logstash-plugins/logstash-input-http/pull/221)
    This fixes an issue where a misconfigured input could retry indefinitely while Logstash's health report continued to report the pipeline as healthy.

**Kafka Integration - 11.8.10**

* Update jackson dependency to 2.21.4 [#269](https://github.com/logstash-plugins/logstash-integration-kafka/pull/269)

**Elasticsearch Output - 12.1.6**

* Fix serverless compatibility: nil params in pool requests and unsupported template settings [#1276](https://github.com/logstash-plugins/logstash-output-elasticsearch/pull/1276)

* Support Elastic Cloud API keys in the `api_key` option, which now accepts an `id:api_key` pair, its base64-encoded form, or an `essu_` Cloud API key, and rejects an unrecognized format at startup [#1274](https://github.com/logstash-plugins/logstash-output-elasticsearch/pull/1274)

* [Doc] Add note for index option [#1269](https://github.com/logstash-plugins/logstash-output-elasticsearch/pull/1269)

## 9.3.7 [logstash-9.3.7-release-notes]

### Updates to dependencies [logstash-9.3.7-dependencies]

Upgrade puma to 8.x [#19228](https://github.com/elastic/logstash/pull/19228)

### Plugins [logstash-plugin-9.3.7-changes]

No user-facing changes in Logstash plugins.

## 9.3.6 [logstash-9.3.6-release-notes]

### Features and enhancements [logstash-9.3.6-features-enhancements]

* Batch's size estimation improvements [#19179](https://github.com/elastic/logstash/pull/19179)

### Updates to documentations [logstash-9.3.6-documentations]

* Logstash's file descriptors usage, limits and sizing guidance documented [#19207](https://github.com/elastic/logstash/pull/19207)

### Plugins [logstash-plugin-9.3.6-changes]

**Azure_event_hubs Input - 1.5.7**

* Upgrades `jackson.core` to 2.21.2 and `nimbus-jose-jwt` to 10.9 versions. [#117](https://github.com/logstash-plugins/logstash-input-azure_event_hubs/pull/117)

* [DOCS] Added recommendation to migrate to the Kafka integration plugin [#116](https://github.com/logstash-plugins/logstash-input-azure_event_hubs/pull/116)

**Beats Input - 7.0.11**

* Update Netty dependency to 4.1.135.Final [#567](https://github.com/logstash-plugins/logstash-input-beats/pull/567)

**Http Input - 4.1.10**

* Update Netty dependency to 4.1.135.Final [#219](https://github.com/logstash-plugins/logstash-input-http/pull/219)

**Tcp Input - 7.0.11**

* Update Netty dependency to 4.1.135.Final [#274](https://github.com/logstash-plugins/logstash-input-tcp/pull/274)

## 9.3.5 [logstash-9.3.5-release-notes]

### Updates to dependencies [logstash-9.3.5-dependencies]

* Updated bundled JDK to 21.0.11 build 10 [#19069](https://github.com/elastic/logstash/pull/19069)
* Updated jruby-openssl to 0.16.0 [#19115](https://github.com/elastic/logstash/pull/19115)
* Upgraded jrjackson and fasterxml.jackson [#19103](https://github.com/elastic/logstash/pull/19103)

### Features and enhancements [logstash-9.3.5-features-enhancements]

* Introduces new `dead_letter_queue.flush_check_interval` config for flushing the staled segment files scheduler which can reduce frequent check overhead [#19036](https://github.com/elastic/logstash/pull/19036)

### Fixes [logstash-9.3.5-fixes]

* Fixes a metric leak in `_node/stats` when a pipeline repeatedly fails to start with `config.reload.automatic: true`. Previously, each retry left a fresh set of plugin metric entries in the collector, causing the stats payload to grow indefinitely [#19091](https://github.com/elastic/logstash/pull/19091)

### Plugins [logstash-plugin-9.3.5-changes]

**Elastic_integration Filter - 9.3.5**

* Fixes an issue where a field set by an integration pipeline to `java.util.Date` value-object representing a timestamp could not be converted to a timestamp [#464](https://github.com/elastic/logstash-filter-elastic_integration/issues/464)

* Include httpclient5/httpcore5 from the `elasticsearch-java` artifact [#457](https://github.com/elastic/logstash-filter-elastic_integration/pull/457)

* Upgrades `tools.jackson.core` dependency to 3.1.1 [#453](https://github.com/elastic/logstash-filter-elastic_integration/pull/453)

**Beats Input - 7.0.10**

* Update Netty dependency to 4.1.134.Final [#541](https://github.com/logstash-plugins/logstash-input-beats/pull/541)

**Elasticsearch Input - 5.2.2**

* [DOC] Note that `search_after` requires permissions on underlying indices/data streams, not aliases [#251](https://github.com/logstash-plugins/logstash-input-elasticsearch/pull/TBD)

**Http Input - 4.1.9**

* Update Netty dependency to 4.1.134.Final [#217](https://github.com/logstash-plugins/logstash-input-http/pull/217)

**Tcp Input - 7.0.10**

* Update Netty dependency to 4.1.134.Final [#257](https://github.com/logstash-plugins/logstash-input-tcp/pull/257)

* When configured to use a port that is already in use, the failure is now propagated to the pipeline [#250](https://github.com/logstash-plugins/logstash-input-tcp/pull/250)
  This fixes an issue where a misconfigured input could retry indefinitely while Logstash's health report continued to report the pipeline as healthy.

**Pipe Output - 3.0.7**

* [DOC] Document `command` string form limitation [#6](https://github.com/logstash-plugins/logstash-output-pipe/pull/6)

**Kafka Integration - 11.8.9**

* Upgrades jackson.core to 2.21.2 version [#255](https://github.com/logstash-plugins/logstash-integration-kafka/pull/255)


## 9.3.4 [logstash-9.3.4-release-notes]

### Updates to dependencies [logstash-9.3.4-dependencies]

* Updated Log4j to 2.25.4 [#18991](https://github.com/elastic/logstash/pull/18991)

### Features and enhancements [logstash-9.3.4-features-enhancements]

* Improved dead letter queue performance during flush operations [#18874](https://github.com/elastic/logstash/pull/18874)
* Optimized DLQ segment directory scans with single-pass logic, saving ~40% CPU on segment file lookup operations [#18970](https://github.com/elastic/logstash/pull/18970)

### Plugins [logstash-plugin-9.3.4-changes]

**Kafka Integration - 11.8.8**

* Fix a regression introduced in 11.8.5 that prevented the Kafka Output plugin from being configured with `sasl_jaas_config` https://github.com/logstash-plugins/logstash-integration-kafka/pull/247[#247]

**Elasticsearch Output - 12.1.3**

* Improves the logging experience when DLQ used [#1253](https://github.com/logstash-plugins/logstash-output-elasticsearch/pull/1253)


## 9.3.3 [logstash-9.3.3-release-notes]

### Plugins [logstash-plugin-9.3.3-changes]

**Azure_event_hubs Input - 1.5.5**

* Upgrades kotlin-stdlib dependency [#114](https://github.com/logstash-plugins/logstash-input-azure_event_hubs/pull/114)

**Beats Input - 7.0.8**

* Update Netty dependency to 4.1.132.Final [#535](https://github.com/logstash-plugins/logstash-input-beats/pull/535)

**Http Input - 4.1.7**

* Update Netty dependency to 4.1.132.Final [#214](https://github.com/logstash-plugins/logstash-input-http/pull/214)

**Tcp Input - 7.0.7**

* Update Netty dependency to 4.1.132.Final [#249](https://github.com/logstash-plugins/logstash-input-tcp/pull/249)

**Kafka Integration - 11.8.7**

* Upgrade Avro dependency to 1.11.5 [#242](https://github.com/logstash-plugins/logstash-integration-kafka/pull/242)

* [DOC] Add info about Kafka timestamp behavior  [#241](https://github.com/logstash-plugins/logstash-integration-kafka/pull/241)

* Redact `sasl_jaas_config` to prevent credentials from appearing in debug logs. [#237](https://github.com/logstash-plugins/logstash-integration-kafka/pull/237)

**Http Output - 6.0.1**

* [DOC] Clarify that `ssl_certificate_authorities` takes at-most-one value [#150](https://github.com/logstash-plugins/logstash-output-http/pull/150)


## 9.3.2 [logstash-9.3.2-release-notes]

### Updates to dependencies [logstash-9.3.2-dependencies]

* Updated the bundled JDK to 21.0.10 build 7

::::{important}

As of JDK 21.0.10, all `TLS_RSA_*` cipher suites are deactivated by default due to their lack of forward secrecy. Connections relying on these suites will fail with an `SSLHandshakeException` and must be migrated to ECDHE-based cipher suites.

::::

### Plugins [logstash-plugin-9.3.2-changes]

**Geoip Filter - 8.0.0**

* Upgraded the bundled MaxMind `geoip2` library to version 4.4.0 [#238](https://github.com/logstash-plugins/logstash-filter-geoip/pull/238)
* Dropped support for Logstash 7.x. Minimum supported version is now Logstash 8.0.0
* Dropped support for Java 8. Minimum required version is now Java 11

**Kafka Integration - 11.8.4**

* Upgraded the `kafka-avro-serializer` dependency [#225](https://github.com/logstash-plugins/logstash-integration-kafka/pull/225)


## 9.3.1 [logstash-9.3.1-release-notes]

### Fixes [logstash-9.3.1-fixes]

* Fixed an issue where some logstash artifacts were shipped with a JDK targeting the wrong platform/architecture. [#18750](https://github.com/elastic/logstash/pull/18750)

### Plugins [logstash-plugin-9.3.1-changes]

**Collectd Codec - 3.1.1**

* Replace deprecated File.exists? by File.exist? to ensure compatibility with Ruby 3.4 (JRuby 10) [#36](https://github.com/logstash-plugins/logstash-codec-collectd/pull/36)

**Netflow Codec - 4.3.4**

* Replace deprecated File.exists? by File.exist? to ensure compatibility with Ruby 3.4 (JRuby 10) [#215](https://github.com/logstash-plugins/logstash-codec-netflow/pull/215)

**Date Filter - 3.1.16**

* Ensure gem artifact ships with all runtime dependencies [#163](https://github.com/logstash-plugins/logstash-filter-date/pull/163)

**Dissect Filter - 1.2.6**

* Ensure gem artifact ships with all runtime dependencies [#93](https://github.com/logstash-plugins/logstash-filter-dissect/pull/93)
* Removed unused runtime dependency [#91](https://github.com/logstash-plugins/logstash-filter-dissect/pull/91)

**Geoip Filter - 7.3.4**

* Replace deprecated File.exists? by File.exist? to ensure compatibility with Ruby 3.4 (JRuby 10) [#239](https://github.com/logstash-plugins/logstash-filter-geoip/pull/239)
* Ensure gem artifact ships with all runtime dependencies [#236](https://github.com/logstash-plugins/logstash-filter-geoip/pull/236)

**Grok Filter - 4.4.4**

* Replace deprecated File.exists? by File.exist? to ensure compatibility with Ruby 3.4 (JRuby 10) [#197](https://github.com/logstash-plugins/logstash-filter-grok/pull/197)

**Beats Input - 7.0.7**

* Upgrade Netty version to 4.1.131 [#531](https://github.com/logstash-plugins/logstash-input-beats/pull/531)
* Ensure gem artifact ships with all runtime dependencies [#527](https://github.com/logstash-plugins/logstash-input-beats/pull/527)

**Dead_letter_queue Input - 2.0.2**

* Ensure gem artifact ships with all runtime dependencies [#57](https://github.com/logstash-plugins/logstash-input-dead_letter_queue/pull/57)

**File Input - 4.4.7**

* Ensure gem artifact ships with all runtime dependencies [#331](https://github.com/logstash-plugins/logstash-input-file/pull/331)

**Http Input - 4.1.6**

* Upgrade Netty version to 4.1.131 [#207](https://github.com/logstash-plugins/logstash-input-http/pull/207)
* Ensure gem artifact ships with all runtime dependencies [#206](https://github.com/logstash-plugins/logstash-input-http/pull/206)

**Tcp Input - 7.0.6**

* Upgrade Netty version to 4.1.131 [#246](https://github.com/logstash-plugins/logstash-input-tcp/pull/246)
* Ensure gem artifact ships with all runtime dependencies [#242](https://github.com/logstash-plugins/logstash-input-tcp/pull/242)

**Unix Input - 3.1.3**

* Replace deprecated File.exists? by File.exist? to ensure compatibility with Ruby 3.4 (JRuby 10) [#31](https://github.com/logstash-plugins/logstash-input-unix/pull/31)

**Jdbc Integration - 5.6.3**

* Replace deprecated File.exists? by File.exist? to ensure compatibility with Ruby 3.4 (JRuby 10) [#192](https://github.com/logstash-plugins/logstash-integration-jdbc/pull/192)
* Ensure gem artifact ships with all runtime dependencies [#190](https://github.com/logstash-plugins/logstash-integration-jdbc/pull/190)

**Kafka Integration - 11.8.3**

* Ensure gem artifact ships with all runtime dependencies [#223](https://github.com/logstash-plugins/logstash-integration-kafka/pull/223)

**Nagios Output - 3.0.7**

* Replace deprecated File.exists? by File.exist? to ensure compatibility with Ruby 3.4 (JRuby 10) [#11](https://github.com/logstash-plugins/logstash-output-nagios/pull/11)

**Webhdfs Output - 3.1.1**

* Ensure gem artifact ships with all runtime dependencies [#49](https://github.com/logstash-plugins/logstash-output-webhdfs/pull/49)

## 9.3.0 [logstash-9.3.0-release-notes]

::::{important}

Do not upgrade to Logstash 9.3.0 if you are running on `aarch64` or Windows with the bundled JDK and are not using Docker.

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

## 9.2.8 [logstash-9.2.8-release-notes]

### Plugins [logstash-plugin-9.2.8-changes]

**Azure_event_hubs Input - 1.5.5**

* Upgrades kotlin-stdlib dependency [#114](https://github.com/logstash-plugins/logstash-input-azure_event_hubs/pull/114)

**Beats Input - 7.0.8**

* Update Netty dependency to 4.1.132.Final [#535](https://github.com/logstash-plugins/logstash-input-beats/pull/535)

**Http Input - 4.1.7**

* Update Netty dependency to 4.1.132.Final [#214](https://github.com/logstash-plugins/logstash-input-http/pull/214)

**Tcp Input - 7.0.7**

* Update Netty dependency to 4.1.132.Final [#249](https://github.com/logstash-plugins/logstash-input-tcp/pull/249)

**Kafka Integration - 11.8.7**

* Upgrade Avro dependency to 1.11.5 [#242](https://github.com/logstash-plugins/logstash-integration-kafka/pull/242)

* [DOC] Add info about Kafka timestamp behavior  [#241](https://github.com/logstash-plugins/logstash-integration-kafka/pull/241)

* Redact `sasl_jaas_config` to prevent credentials from appearing in debug logs. [#237](https://github.com/logstash-plugins/logstash-integration-kafka/pull/237)

**Http Output - 6.0.1**

* [DOC] Clarify that `ssl_certificate_authorities` takes at-most-one value [#150](https://github.com/logstash-plugins/logstash-output-http/pull/150)

## 9.2.7 [logstash-9.2.7-release-notes]

### Updates to dependencies [logstash-9.2.7-dependencies]

* Updated the bundled JDK to 21.0.10 build 7
* Upgraded Log4j to 2.25.3 [#18805](https://github.com/elastic/logstash/pull/18805)

### Plugins [logstash-plugin-9.2.7-changes]

**Geoip Filter - 8.0.0**

* Updated MaxMind GeoIP2 database library to version 4.4.0 [#238](https://github.com/logstash-plugins/logstash-filter-geoip/pull/238)
* Dropped support for Logstash 7.x. Minimum supported version is now Logstash 8.0.0
* Dropped support for Java 8. Minimum required Java version is now Java 11

**Kafka Integration - 11.8.4**

* Upgraded the `kafka-avro-serializer` dependency [#225](https://github.com/logstash-plugins/logstash-integration-kafka/pull/225)

## 9.2.6 [logstash-9.2.6-release-notes]

### Fixes [logstash-9.2.6-fixes]

* Fixed an issue where some logstash artifacts were shipped with a JDK targeting the wrong platform/architecture. [#18749](https://github.com/elastic/logstash/pull/18749)

### Plugins [logstash-plugin-9.2.6-changes]

**Collectd Codec - 3.1.1**

* Replace deprecated File.exists? by File.exist? to ensure compatibility with Ruby 3.4 (JRuby 10) [#36](https://github.com/logstash-plugins/logstash-codec-collectd/pull/36)

**Netflow Codec - 4.3.4**

* Replace deprecated File.exists? by File.exist? to ensure compatibility with Ruby 3.4 (JRuby 10) [#215](https://github.com/logstash-plugins/logstash-codec-netflow/pull/215)

**Date Filter - 3.1.16**

* Ensure gem artifact ships with all runtime dependencies [#163](https://github.com/logstash-plugins/logstash-filter-date/pull/163)

**Dissect Filter - 1.2.6**

* Ensure gem artifact ships with all runtime dependencies [#93](https://github.com/logstash-plugins/logstash-filter-dissect/pull/93)
* Removed unused runtime dependency [#91](https://github.com/logstash-plugins/logstash-filter-dissect/pull/91)

**Geoip Filter - 7.3.4**

* Replace deprecated File.exists? by File.exist? to ensure compatibility with Ruby 3.4 (JRuby 10) [#239](https://github.com/logstash-plugins/logstash-filter-geoip/pull/239)
* Ensure gem artifact ships with all runtime dependencies [#236](https://github.com/logstash-plugins/logstash-filter-geoip/pull/236)

**Grok Filter - 4.4.4**

* Replace deprecated File.exists? by File.exist? to ensure compatibility with Ruby 3.4 (JRuby 10) [#197](https://github.com/logstash-plugins/logstash-filter-grok/pull/197)

**Beats Input - 7.0.7**

* Upgrade Netty version to 4.1.131 [#531](https://github.com/logstash-plugins/logstash-input-beats/pull/531)
* Ensure gem artifact ships with all runtime dependencies [#527](https://github.com/logstash-plugins/logstash-input-beats/pull/527)

**Dead_letter_queue Input - 2.0.2**

* Ensure gem artifact ships with all runtime dependencies [#57](https://github.com/logstash-plugins/logstash-input-dead_letter_queue/pull/57)

**File Input - 4.4.7**

* Ensure gem artifact ships with all runtime dependencies [#331](https://github.com/logstash-plugins/logstash-input-file/pull/331)

**Http Input - 4.1.6**

* Upgrade Netty version to 4.1.131 [#207](https://github.com/logstash-plugins/logstash-input-http/pull/207)
* Ensure gem artifact ships with all runtime dependencies [#206](https://github.com/logstash-plugins/logstash-input-http/pull/206)

**Tcp Input - 7.0.6**

* Upgrade Netty version to 4.1.131 [#246](https://github.com/logstash-plugins/logstash-input-tcp/pull/246)
* Ensure gem artifact ships with all runtime dependencies [#242](https://github.com/logstash-plugins/logstash-input-tcp/pull/242)

**Unix Input - 3.1.3**

* Replace deprecated File.exists? by File.exist? to ensure compatibility with Ruby 3.4 (JRuby 10) [#31](https://github.com/logstash-plugins/logstash-input-unix/pull/31)

**Jdbc Integration - 5.6.3**

* Replace deprecated File.exists? by File.exist? to ensure compatibility with Ruby 3.4 (JRuby 10) [#192](https://github.com/logstash-plugins/logstash-integration-jdbc/pull/192)
* Ensure gem artifact ships with all runtime dependencies [#190](https://github.com/logstash-plugins/logstash-integration-jdbc/pull/190)

**Kafka Integration - 11.8.3**

* Ensure gem artifact ships with all runtime dependencies [#223](https://github.com/logstash-plugins/logstash-integration-kafka/pull/223)

**Nagios Output - 3.0.7**

* Replace deprecated File.exists? by File.exist? to ensure compatibility with Ruby 3.4 (JRuby 10) [#11](https://github.com/logstash-plugins/logstash-output-nagios/pull/11)

**Webhdfs Output - 3.1.1**

* Ensure gem artifact ships with all runtime dependencies [#49](https://github.com/logstash-plugins/logstash-output-webhdfs/pull/49)

## 9.2.5 [logstash-9.2.5-release-notes]

::::{important}

Do not upgrade to Logstash 9.2.5 if you are running on `aarch64` or Windows with the bundled JDK and are not using Docker.

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