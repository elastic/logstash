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

## 9.0.1 [logstash-901-release-notes]

###  Features and enhancements [logstash-901-features-enhancements]

---------- GENERATED CONTENT STARTS HERE ------------
=== Logstash Pull Requests with label v9.0.1

=== Logstash Commits between 9.0 and 9.0.0

Computed with "git log --pretty=format:'%h -%d %s (%cr) <%an>' --abbrev-commit --date=relative v9.0.0..9.0"

dbe80b490 - (HEAD -> 9.0, origin/9.0) [docs] Fix various syntax and rendering errors (#17580) (#17583) (26 hours ago) <mergify[bot]>
2db9b69c5 - Add helper method to wait for log message to be observed (#17589) (#17608) (27 hours ago) <mergify[bot]>
a2a2e45bc - Make redhat exhaustive test install command more robust (#17592) (#17604) (27 hours ago) <mergify[bot]>
4e850d791 - bump lock file for 9.0 (#17599) (31 hours ago) <github-actions[bot]>
97b50c8ff - upgrade jdk to 21.0.7+6 (#17591) (#17596) (2 days ago) <mergify[bot]>
2045dc196 - Improve the key validation in secret identifier. (#17351) (#17588) (7 days ago) <mergify[bot]>
7a06c2699 - Doc: Remove local k8s files (#17547) (#17574) (13 days ago) <mergify[bot]>
d04296e1a - Remove ADOC preview link (#17496) (#17573) (13 days ago) <mergify[bot]>
1b06d13d4 - set major-version to "9.x" used only for the package installation section (#17562) (#17571) (13 days ago) <mergify[bot]>
9f2a99911 - Doc: Fix image paths for docs-assembler (#17566) (#17568) (2 weeks ago) <mergify[bot]>
71c133e55 - Bump to 9.0.1 (#17558) (2 weeks ago) <Mashhur>
a813cc98b - Update index.md (#17548) (#17549) (3 weeks ago) <mergify[bot]>
d7e38e5bf - Ensure elasticsearch logs and data dirs exist before startup (#17531) (#17533) (3 weeks ago) <mergify[bot]>
17be259eb - Doc: Update installation info (#17532) (#17540) (3 weeks ago) <mergify[bot]>
b44300d4e - updates to docker image template based on feedback (#17494) (#17525) (3 weeks ago) <mergify[bot]>
87e096476 - [Monitoring LS] Recommends collecting metricsets to fully visualize metrics on dashboards. (#17479) (#17521) (3 weeks ago) <mergify[bot]>
47fc185a8 - Fix standalone agent access for agent-driven monitoring (#17386) (#17476) (3 weeks ago) <mergify[bot]>
fcf313ae9 - Fix JDK matrix pipeline after configurable it split (#17461) (#17514) (3 weeks ago) <mergify[bot]>
a14c8ded4 - Release notes, deprecations, breaking for 9.0.0 (#17507) (#17509) (3 weeks ago) <mergify[bot]>
402fe1823 - Doc: Incorporate field ref deep dive content (#17484) (#17508) (3 weeks ago) <mergify[bot]>
12e66590c - pin cgi to 0.3.7 (#17487) (#17488) (4 weeks ago) <mergify[bot]>
d4a2a1eac - Remove tech preview from agent driven LS monitoring pages. (#17482) (#17483) (4 weeks ago) <mergify[bot]>
0d162a533 - Breaking changes for 9.0 (#17380) (#17480) (4 weeks ago) <mergify[bot]>
6c1fcdb30 - remove reliance on redirects (#17440) (#17443) (4 weeks ago) <mergify[bot]>
440d2277f - Doc: Move 9.0 pre-release notes to release notes (#17439) (#17474) (4 weeks ago) <mergify[bot]>
885706813 - Fix persistent-queues.md PQ sizing multiplication factors #17451 (#17452) (#17468) (4 weeks ago) <mergify[bot]>
13c577918 - [Backport 9.0] Fix syntax in BK CI script (#17462) (#17467) (4 weeks ago) <mergify[bot]>
7bab8425d - ci(backport): remove former approach (#17347) (#17456) (4 weeks ago) <mergify[bot]>
e05d30635 - [9.0] Pin rubocop-ast development gem due to new dep on prism (backport #17407) (#17424) (5 weeks ago) <mergify[bot]>
61547355c - Doc: Remove plugin docs from logstash core (#17405) (#17432) (5 weeks ago) <mergify[bot]>
11c91a2a3 - [Backport 9.0]Limit memory consumption in test on overflow (#17373) (#17415) (5 weeks ago) <mergify[bot]>
21d9d6845 - Fix Elasticsearch output SSL settings (#17391) (#17397) (5 weeks ago) <mergify[bot]>
caa059998 - Doc: Upgrade content improvements (#17403) (#17430) (5 weeks ago) <mergify[bot]>
494903ef0 - Added test to verify the int overflow happen (#17353) (#17358) (5 weeks ago) <mergify[bot]>
48857958f - Updates navigation titles and descriptions for release notes (#17381) (#17384) (6 weeks ago) <mergify[bot]>
d072ab0c1 - [docs] Miscellaneous docs clean up (#17372) (#17383) (6 weeks ago) <mergify[bot]>
3092c03e5 - Doc: Fix upgrade TOC structure (#17361) (#17382) (6 weeks ago) <mergify[bot]>
03e68b231 - tests: make integration split quantity configurable (#17219) (#17371) (6 weeks ago) <mergify[bot]>
232594149 - Disable support of OpenJDK 17 (#17338) (#17366) (6 weeks ago) <mergify[bot]>
7e53175d9 - add ci shared qualified-version script (#17311) (#17350) (6 weeks ago) <mergify[bot]>

=== Logstash Plugin Release Changelogs ===
Computed from "git diff v9.0.0..9.0 *.release"
Changed plugin versions:
logstash-filter-elastic_integration: 9.0.0 -> 9.0.0
logstash-filter-xml: 4.3.0 -> 4.3.1
logstash-output-elasticsearch: 12.0.2 -> 12.0.3
logstash-output-tcp: 7.0.0 -> 7.0.1
---------- GENERATED CONTENT ENDS HERE ------------

### Plugins [logstash-plugin-901-changes]

**Elastic_integration Filter - 9.0.0**

404: Not Found

**Xml Filter - 4.3.1**

* Update Nokogiri dependency version https://github.com/logstash-plugins/logstash-filter-xml/pull/88[#88]

**Elasticsearch Output - 12.0.3**

* Demote connection log entry from WARN to INFO connection during register phase https://github.com/logstash-plugins/logstash-output-elasticsearch/pull/1211[#1211]

**Tcp Output - 7.0.1**

* Invoke post_connection_check on connect https://github.com/logstash-plugins/logstash-output-tcp/pull/61[#61]


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