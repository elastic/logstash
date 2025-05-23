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


## 9.0.2 [logstash-9.0.2-release-notes]

### Features and enhancements [logstash-9.0.2-features-enhancements]

---------- GENERATED CONTENT STARTS HERE ------------
=== Logstash Pull Requests with label v9.0.2

=== Logstash Commits between 9.0 and 9.0.1

Computed with "git log --pretty=format:'%h -%d %s (%cr) <%an>' --abbrev-commit --date=relative v9.0.1..9.0"

b1ce9e8f2 - (HEAD -> 9.0, origin/9.0) Update Grype GH action to v6 (#17666) (#17670) (2 days ago) <mergify[bot]>
5aa2cf16b - update jruby-openssl to 0.15.4  (#17650) (#17671) (2 days ago) <mergify[bot]>
6b9c30fdc - Updated to latest Kafka integration plugin in lockfile(#17665) (2 days ago) <Andrea Selva>
0593458e0 - [9.0] Fixes to the bundles gems and jars versions (backport #17659) (#17664) (3 days ago) <mergify[bot]>
04da5fcd4 - bump lock file for 9.0 (#17658) (3 days ago) <github-actions[bot]>
0fc31322a - add products to docset.yml (#17654) (#17655) (4 days ago) <mergify[bot]>
dcccfc419 - Doc: Fix link (#17649) (#17651) (2 weeks ago) <mergify[bot]>
70fae591e - Fix typo in Logstash docs (#17645) (#17647) (2 weeks ago) <mergify[bot]>
3e20c9bc9 - release notes 9.0.1 updated with security advisor (#17643) (#17644) (2 weeks ago) <mergify[bot]>
468d45e0c - [chore] update ID format of release notes tool (#17636) (#17637) (2 weeks ago) <mergify[bot]>
f6d5500e4 - setting: enforce non-nullable (restore 8.15.x behavior) (#17522) (#17530) (2 weeks ago) <mergify[bot]>
b2850bf3d - [9.0] Update uri gem required by Logstash (backport #17495) (#17503) (2 weeks ago) <mergify[bot]>
815cf66bf - Removed unused configHash computation that can be replaced by PipelineConfig.configHash() (#17336) (#17419) (2 weeks ago) <mergify[bot]>
c03513a20 - bump core 9.0.2 (#17630) (2 weeks ago) <kaisecheng>
d6f95fe08 - Update index.md (2 weeks ago) <kaisecheng>
8b8253a9a - Release notes for 9.0.1 (#17620) (3 weeks ago) <github-actions[bot]>
e6f8a73fc - [chore] fix release note url generation (#17624) (#17625) (3 weeks ago) <mergify[bot]>
aa4afaa26 - [9.0] (backport #17621) [chore] support markdown and asciidoc release notes (#17622) (3 weeks ago) <mergify[bot]>
dbe80b490 - [docs] Fix various syntax and rendering errors (#17580) (#17583) (3 weeks ago) <mergify[bot]>
2db9b69c5 - Add helper method to wait for log message to be observed (#17589) (#17608) (3 weeks ago) <mergify[bot]>
a2a2e45bc - Make redhat exhaustive test install command more robust (#17592) (#17604) (3 weeks ago) <mergify[bot]>

=== Logstash Plugin Release Changelogs ===
Computed from "git diff v9.0.1..9.0 *.release"
Changed plugin versions:
logstash-integration-kafka: 11.6.0 -> 11.6.2
---------- GENERATED CONTENT ENDS HERE ------------

### Plugins [logstash-plugin-9.0.2-changes]

**Kafka Integration - 11.6.2**

* Docs: fixed setting type reference for `sasl_iam_jar_paths` [#192](https://github.com/logstash-plugins/logstash-integration-kafka/pull/192)   

* Expose the SASL client callback class setting to the Logstash configuration [#177](https://github.com/logstash-plugins/logstash-integration-kafka/pull/177)
* Adds a mechanism to load AWS IAM authentication as SASL client libraries at startup [#178](https://github.com/logstash-plugins/logstash-integration-kafka/pull/178)


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