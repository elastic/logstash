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

## 9.4.0 [logstash-9.4.0-release-notes]

### Features and enhancements [logstash-9.4.0-features-enhancements]

---------- GENERATED CONTENT STARTS HERE ------------
=== Logstash Pull Requests with label v9.4.0

=== Logstash Commits between 9.4 and 9.3.3

Computed with "git log --pretty=format:'%h -%d %s (%cr) <%an>' --abbrev-commit --date=relative v9.3.3..9.4"

120c22488 - (HEAD -> 9.4, origin/9.4) Update jruby to 10.0.5.0 (#18965) (#18966) (6 hours ago) <mergify[bot]>
796ae46b3 - Support REACTIVE pipeline recovery with config.reload manager (#18930) (#18967) (19 hours ago) <Rye Biesemeyer>
91bf0432f - DeadLetterQueueUtils#extractSegmentId improvement: replace split with index of and substring methods. (#18874) (#18961) (2 days ago) <mergify[bot]>
a5c10b3ea - [9.4 release] Copy gemfile.lock from 9.3 (#18954) (2 days ago) <Edmo Vamerlatti Costa>
f654c28d7 - [main] (backport #18945) Release notes for 9.2.8 (#18951) (3 days ago) <mergify[bot]>
a608dd033 - Release notes for 9.3.3 (#18946) (#18952) (3 days ago) <mergify[bot]>
70c8e1a7e - tests(health api): extract specific assertions from list validator (#18937) (3 days ago) <Rye Biesemeyer>
eb3756b48 - Add jruby JAR path to the plugins Snyk scanning pipeline. (#18912) (3 days ago) <Mashhur>
3ac9c2af2 - Bump docker/login-action in the github-actions group across 1 directory (#18940) (3 days ago) <dependabot[bot]>
0f5362de8 - (origin/updatecli_main_ironbank/template) Update the ES creation helper function to teardown it in case of service not available. (#18931) (7 days ago) <Andrea Selva>
fcfcea0c3 - Improve xpack integration test UX (#18919) (7 days ago) <Kaise>
f54cb2cd7 - Enabled lifetime window for batch's byte size metric (#18911) (8 days ago) <Andrea Selva>
cc36cef17 - Fix comparison of ES SHA, (#18923) (8 days ago) <Andrea Selva>
f614ad4ae - Removes ruby-maven-libs maven dependency, which doesn't exits. (#18913) (10 days ago) <Mashhur>
fd3f189bc - chore: deps(updatecli): Bump updatecli version to v0.115.0 (#18914) (10 days ago) <github-actions[bot]>
6ef0fbb9f - Move docs workflows to elastic/docs-actions (#18915) (10 days ago) <Martijn Laarman>
c4d7362b5 - Adds verification of the file name (#18848) (13 days ago) <Andrea Selva>
29048954d - Bump requests in /.buildkite/scripts/health-report-tests (#18904) (2 weeks ago) <dependabot[bot]>
3b59fb59d - Add tests for Oracle Linux 9 (#18891) (2 weeks ago) <Rob Bavey>
28d384411 - Add max value for batch size windowed histograms (#18850) (2 weeks ago) <Andrea Selva>
1db2e098c - Doc/describe usage of batch structure metrics in pipeline tuning (#18828) (2 weeks ago) <Andrea Selva>
ad00a443e - Bump https://github.com/pre-commit/pre-commit-hooks from v4.6.0 to 6.0.0 (#18853) (2 weeks ago) <dependabot[bot]>
0cadaa455 - (origin/mergify/bp/main/pr-18882, origin/mergify/bp/main/pr-18881, origin/mergify/bp/main/pr-18880, origin/mergify/bp/main/pr-18879, origin/mergify/bp/main/pr-18878, origin/mergify/bp/main/pr-18877, origin/mergify/bp/main/pr-18876, origin/mergify/bp/main/pr-18875) Doc: Add page-level applies_to tags to Logstash content Group 4 (#18861) (2 weeks ago) <Karen Metts>
13067534f - Doc: Add page-level applies_to tags to Logstash content (Group 3) (#18860) (2 weeks ago) <Karen Metts>
5aa258487 - Doc: Add page-level applies_to tags to Logstash content Group 2 (#18859) (2 weeks ago) <Karen Metts>
dcda062a7 - Doc: Add page-level applies_to tags to Logstash docs (Group 1) (#18858) (2 weeks ago) <Karen Metts>
97603f924 - add DRA version bump pipeline (#18765) (2 weeks ago) <ninalee12>
ee364ac80 - Bump anchore/scan-action in the github-actions group across 1 directory (#18873) (2 weeks ago) <dependabot[bot]>
c13b69245 - upgrade jruby to 10.0.4.0 (#18856) (3 weeks ago) <João Duarte>
42a5ecafe - Release notes for 9.3.2 (#18845) (#18864) (3 weeks ago) <mergify[bot]>
dbc3be75b - [main] (backport #18843) Release notes for 9.2.7 (#18863) (3 weeks ago) <mergify[bot]>
9ffa9d682 - Bump actions/setup-java in the github-actions group across 1 directory (#18854) (3 weeks ago) <dependabot[bot]>
f8148b42c - bump jrjackson to 0.4.21 for jruby 10 support (#18862) (3 weeks ago) <João Duarte>
7114f1b68 - Add AGENTS.md coding agent guidance for core, QA, and X-Pack (#18771) (4 weeks ago) <João Duarte>
9ce49ad02 - Fix Bundler platform genericization for JRuby 10. (#18852) (4 weeks ago) <João Duarte>
34add6ca8 - github-action: include the dependabot section for pre-commit (#18847) (4 weeks ago) <elastic-vault-github-plugin-prod[bot]>
ecadb4ac3 - Upgrade Logstash to JRuby 10.0.3.0 and Ruby 3.4 (4 weeks ago) <João Duarte>
298d894b0 - Fix observabilitySRE tests (#18835) (4 weeks ago) <Cas Donoghue>
a371ac111 - Bump docker/login-action in the github-actions group across 1 directory (#18834) (4 weeks ago) <dependabot[bot]>
cb3efde08 - Update .mergify.yml (#18831) (5 weeks ago) <Victor Martinez>
096b30b8d - Adds histogram flow metrics to expose some percentiles of the batch's size and event count (#18770) (5 weeks ago) <Andrea Selva>
bd6f6886e - Removes SplittableStringArray setting used only in Logstash modules, that doesn't exist anymore. (#18826) (5 weeks ago) <Andrea Selva>
ceba9dcc8 - chore: deps(updatecli): Bump updatecli version to v0.114.0 (#18827) (5 weeks ago) <github-actions[bot]>
5c73a8f06 - Periodically run exhaustive tests on artifacts prepared with DRA pipeline (#18803) (6 weeks ago) <Cas Donoghue>
5d4f709e5 - Dont run exhaustive tests on *EVERY* commmit in a branch (#18817) (6 weeks ago) <Cas Donoghue>
d0e5d88ff - Update bundled JDK to 21.0.10 build 7 (#18783) (6 weeks ago) <github-actions[bot]>
7c7eff92b - Moves TimeValue setting to java (#18760) (6 weeks ago) <Andrea Selva>
75172968c - Add new config option to split batch into chunks before outputs (#18680) (6 weeks ago) <Emily S>
a44fbda69 - Add Vale docs linting support (#18806) (6 weeks ago) <Fabrizio Ferri-Benedetti>
377066af3 - [main] (backport #18798) Release notes for 9.2.6 (#18812) (6 weeks ago) <mergify[bot]>
2197643f3 - Release notes for 9.3.1 (#18799) (#18811) (6 weeks ago) <mergify[bot]>
aba00f54e - Revise known issues for Logstash 9.3.0 and 9.2.5 (#18800) (#18801) (6 weeks ago) <mergify[bot]>
4d0868371 - Add known issues running 9.2.5 on aarch64 architectures (#18731) (#18735) (#18736) (7 weeks ago) <mergify[bot]>
9e368a51e - Add known issues about aarch64 to release notes (#18730) (#18802) (7 weeks ago) <mergify[bot]>
9f14abf79 - Test rpm and deb packages on aarch64 in exhaustive test pipeline (#18780) (7 weeks ago) <Cas Donoghue>
93bdbed6a - bk(pr-buildkite-bot): reverting to the original scope (#18790) (7 weeks ago) <Victor Martinez>
b39e61ee5 - (origin/mergify/bp/main/pr-18792, origin/mergify/bp/main/pr-18791) Doc: Update svrless docs to use endpoint url (#18773) (7 weeks ago) <Karen Metts>
201068a14 - Improve x-pack RSpec support with automatic path detection (#18785) (7 weeks ago) <kaisecheng>
1f1ee1cb3 - Avoid duplicate steps in snyk artifact scanning (#18768) (7 weeks ago) <Cas Donoghue>
eecd5eabd - bk(comment-trigger): support case insensitive (#18737) (7 weeks ago) <Victor Martinez>
00c304883 - ci: Add almalinux-8 / 9 and rocky-9 to exhaustive compat linux group (#18752) (8 weeks ago) <Victor Martinez>
b05f0ddf0 - Genericise Flow Metrics' RetentionWindow (#18624) (8 weeks ago) <Rye Biesemeyer>
4eee56590 - Removed modules setting not existing anymore (#18761) (8 weeks ago) <Andrea Selva>
0d99eb671 - Bump anchore/scan-action in the github-actions group across 1 directory (#18754) (8 weeks ago) <dependabot[bot]>
1bc95f68e - Move Bytes setting to Java (#18709) (8 weeks ago) <Andrea Selva>
41cb3b784 - remove dependency on org.reflections (#18295) (9 weeks ago) <João Duarte>
7f1ca8eea - Respect ARCH env var when downloading JDK via gradle (#18733) (9 weeks ago) <Cas Donoghue>
74a2bbfff - [CI] Sync acceptance test OS matrix with JDK matrix pipeline (#18739) (9 weeks ago) <Álex Cámara Lara>
8c58270eb - Restore missing "skip windows" logic in test (#18724) (9 weeks ago) <Cas Donoghue>
7ba6f3341 - Clarify input param to bump LS version GHA (#18715) (9 weeks ago) <Cas Donoghue>
95801bace - WritableDirectory setting move to Java (#18630) (9 weeks ago) <Andrea Selva>
d23ba272a - Add Debian 13 to linux matrix (#18698) (9 weeks ago) <Álex Cámara Lara>
69aa99bb3 - Steel thread for sbom generation for snyk scanning (#18690) (9 weeks ago) <Cas Donoghue>
58487f210 - Revert "Allow exhaustive tests to be triggered by org members (#18616)" (#18692) (9 weeks ago) <Victor Martinez>
8b02b4d12 - [main] (backport #18703) 9.3.0 release notes (copied from messed PR-18581) (#18704) (9 weeks ago) <mergify[bot]>
272394473 - Fix obserbabilitySRE DRA jobs after docker update on runners (#18699) (9 weeks ago) <Cas Donoghue>
18a87eec4 - updatecli: bump ironbank policy (#18697) (9 weeks ago) <Victor Martinez>
38834fb6a - Moved ByteValue utilities methods and constants from Ruby to Java (#18679) (9 weeks ago) <Andrea Selva>
00d9f67d5 - [main] (backport #18678) Release notes for 9.2.5 (#18695) (9 weeks ago) <mergify[bot]>
43a24a563 - Bump the github-actions group across 1 directory with 2 updates (#18691) (9 weeks ago) <dependabot[bot]>
63f19c395 - Add Snyk scanning for Logstash release artifacts (#18557) (10 weeks ago) <Cas Donoghue>
87b9f69d3 - Ensure jruby managed with gradle bootstrap is used everywher in CI (#18676) (10 weeks ago) <Cas Donoghue>
44db4c916 - Fix smart exhaustive test pipeline (#18661) (10 weeks ago) <Cas Donoghue>
38ced219a - Bump requests in /.buildkite/scripts/health-report-tests (#17702) (2 months ago) <dependabot[bot]>
e9380e91a - Update RedHat Ironbank UBI image to long term support 10.1 (#18619) (2 months ago) <Álex Cámara Lara>
0ef710ba6 - Bump anchore/scan-action in the github-actions group across 1 directory (#18647) (2 months ago) <dependabot[bot]>
e2df0027c - Only raise PR to bump java version when all artifacts are ready (#18668) (2 months ago) <Cas Donoghue>
23f53db49 - Revert "Update bundled JDK to 21.0.10 build 7 (#18649)" (#18662) (2 months ago) <Cas Donoghue>
37305e7ba - Update bundled JDK to 21.0.10 build 7 (#18649) (2 months ago) <github-actions[bot]>
b26334404 - Dont persist bundler config state across ci tasks (#18655) (2 months ago) <Cas Donoghue>
95b706a77 - Change the default logger level for licensereader (#18644) (2 months ago) <kaisecheng>
205d8ab78 - Consistent bundled jruby across all CI tasks (#18615) (3 months ago) <Cas Donoghue>
190afc13e - test artifact upgrade from 8.19 instead of 7.17 (#18635) (3 months ago) <João Duarte>
a86a6f65d - Reimplemented Ruby's ExistingFilePath setting into Java (#18614) (3 months ago) <Andrea Selva>
1d963dcc5 - Reimplemented Ruby's CoercibleString setting into Java (#18187) (3 months ago) <Andrea Selva>
7e9c38455 - Use gradle and bundled jruby for acceptance tests orchestration (#18536) (3 months ago) <Cas Donoghue>
835934310 - Fix ironbank container build (#18625) (3 months ago) <Cas Donoghue>
337d2e437 - Allow exhaustive tests to be triggered by org members (#18616) (3 months ago) <Cas Donoghue>
e1684280d - Add Ironbank acceptance tests to CI (#18585) (3 months ago) <Álex Cámara Lara>
4c158701b - Remove unused/unreachable rake tasks (#18537) (3 months ago) <Cas Donoghue>
28c810d73 - Remove unused gradle tasks (#18526) (3 months ago) <Cas Donoghue>
b6760b826 - chore: deps(updatecli): Bump updatecli version to v0.113.0 (#18597) (3 months ago) <github-actions[bot]>
064c39abf - chore: delete SECURITY.md to use organization-wide policy (#18577) (3 months ago) <Paul McCann>
bd4cec075 - Only ship x-pack library code with artifacts (#18548) (3 months ago) <Cas Donoghue>
ae9fce6a4 - (origin/mergify/bp/main/pr-18588, origin/mergify/bp/main/pr-18587, origin/mergify/bp/main/pr-18586) Doc: Use new version syntax (#18580) (3 months ago) <Colleen McGinnis>
1d9eb5b1e - 7.17 reached EoL (#18559) (3 months ago) <Victor Martinez>
602cda05b - Plugin snyk scan: Only runtime dependencies scanning, exclude test & compile deps for now. (#18562) (3 months ago) <Mashhur>
d7a920e4f - docs: update security url (#18566) (3 months ago) <Paul McCann>
b7f37ebfd - Bump anchore/scan-action in the github-actions group across 1 directory (#18561) (3 months ago) <dependabot[bot]>
707a4c99c - Upgrade Log4j to 2.25.3 (#18522) (3 months ago) <João Duarte>
f9d8b771e - Snyk scanning pipeline fixes. (#18499) (3 months ago) <Mashhur>
9eeeb92b5 - Bump logstash version 9.4.0 (#18523) (4 months ago) <github-actions[bot]>
f36ba65de - Stop tests from polluting maven settings (#18525) (4 months ago) <Cas Donoghue>
ca1fe3761 - Make gradle the root of every dependency graph (#18471) (4 months ago) <Cas Donoghue>
1be3a3547 - Fix, clean batch metrics on pipeline shutdown (#18515) (4 months ago) <Andrea Selva>
cf1eee34f - Revert "Keep psych minor version in line with jruby 9.4.13.0 (#18507)" (#18516) (4 months ago) <Cas Donoghue>
a089904f3 - Keep psych minor version in line with jruby 9.4.13.0 (#18507) (4 months ago) <Cas Donoghue>
21b2d5ffe - Revert "[9.3 release] Copy Gemfile from 9.2 branch and update only LS core ve…" (#18505) (4 months ago) <Mashhur>
603d2fcc1 - [9.3 release] Copy Gemfile from 9.2 branch and update only LS core version. (#18504) (4 months ago) <Mashhur>

=== Logstash Plugin Release Changelogs ===
Computed from "git diff v9.3.3..9.4 *.release"
Changed plugin versions:
logstash-core-plugin-api: 2.1.16 -> 2.1.16
logstash-codec-avro: 3.5.0 -> 3.5.0
logstash-codec-cef: 6.2.8 -> 6.2.8
logstash-codec-collectd: 3.1.1 -> 3.1.1
logstash-codec-dots: 3.0.6 -> 3.0.6
logstash-codec-edn: 3.1.0 -> 3.1.0
logstash-codec-edn_lines: 3.1.0 -> 3.1.0
logstash-codec-es_bulk: 3.1.0 -> 3.1.0
logstash-codec-fluent: 3.4.3 -> 3.4.3
logstash-codec-graphite: 3.0.6 -> 3.0.6
logstash-codec-json: 3.1.1 -> 3.1.1
logstash-codec-json_lines: 3.2.2 -> 3.2.2
logstash-codec-line: 3.1.1 -> 3.1.1
logstash-codec-msgpack: 3.1.0 -> 3.1.0
logstash-codec-multiline: 3.1.2 -> 3.1.2
logstash-codec-netflow: 4.3.4 -> 4.3.4
logstash-codec-plain: 3.1.0 -> 3.1.0
logstash-codec-rubydebug: 3.1.0 -> 3.1.0
logstash-filter-aggregate: 2.11.0 -> 2.11.0
logstash-filter-anonymize: 3.0.7 -> 3.0.7
logstash-filter-cidr: 3.2.0 -> 3.2.0
logstash-filter-clone: 4.2.0 -> 4.2.0
logstash-filter-csv: 3.1.1 -> 3.1.1
logstash-filter-date: 3.2.0 -> 3.2.0
logstash-filter-de_dot: 1.1.0 -> 1.1.0
logstash-filter-dissect: 1.3.0 -> 1.3.0
logstash-filter-dns: 3.2.0 -> 3.2.0
logstash-filter-drop: 3.0.5 -> 3.0.5
logstash-filter-elastic_integration: 9.3.2 -> 9.3.2
logstash-filter-elasticsearch: 4.3.1 -> 4.3.1
logstash-filter-fingerprint: 3.5.0 -> 3.5.0
logstash-filter-geoip: 8.0.0 -> 8.0.0
logstash-filter-grok: 4.4.4 -> 4.4.4
logstash-filter-http: 2.0.0 -> 2.0.0
logstash-filter-json: 3.2.1 -> 3.2.1
logstash-filter-kv: 4.7.0 -> 4.7.0
logstash-filter-memcached: 1.2.0 -> 1.2.0
logstash-filter-metrics: 4.0.7 -> 4.0.7
logstash-filter-mutate: 3.6.0 -> 3.6.0
logstash-filter-prune: 3.0.4 -> 3.0.4
logstash-filter-ruby: 3.1.8 -> 3.1.8
logstash-filter-sleep: 3.0.7 -> 3.0.7
logstash-filter-split: 3.1.10 -> 3.1.10
logstash-filter-syslog_pri: 3.2.1 -> 3.2.1
logstash-filter-throttle: 4.0.4 -> 4.0.4
logstash-filter-translate: 3.5.0 -> 3.5.0
logstash-filter-truncate: 1.0.6 -> 1.0.6
logstash-filter-urldecode: 3.0.6 -> 3.0.6
logstash-filter-useragent: 3.3.5 -> 3.3.5
logstash-filter-uuid: 3.0.5 -> 3.0.5
logstash-filter-xml: 4.3.2 -> 4.3.2
logstash-input-azure_event_hubs: 1.5.5 -> 1.5.5
logstash-input-beats: 7.0.8 -> 7.0.8
logstash-input-couchdb_changes: 3.1.6 -> 3.1.6
logstash-input-dead_letter_queue: 2.0.2 -> 2.0.2
logstash-input-elastic_serverless_forwarder: 2.0.0 -> 2.0.0
logstash-input-elasticsearch: 5.2.1 -> 5.2.1
logstash-input-exec: 3.6.0 -> 3.6.0
logstash-input-file: 4.4.7 -> 4.4.7
logstash-input-ganglia: 3.1.4 -> 3.1.4
logstash-input-gelf: 3.4.0 -> 3.4.0
logstash-input-generator: 3.1.0 -> 3.1.0
logstash-input-graphite: 3.0.6 -> 3.0.6
logstash-input-heartbeat: 3.1.1 -> 3.1.1
logstash-input-http: 4.1.7 -> 4.1.7
logstash-input-http_poller: 6.0.0 -> 6.0.0
logstash-input-jms: 3.3.1 -> 3.3.1
logstash-input-pipe: 3.1.0 -> 3.1.0
logstash-input-redis: 3.7.1 -> 3.7.1
logstash-input-stdin: 3.4.0 -> 3.4.0
logstash-input-syslog: 3.7.1 -> 3.7.1
logstash-input-tcp: 7.0.7 -> 7.0.7
logstash-input-twitter: 4.1.1 -> 4.1.1
logstash-input-udp: 3.5.0 -> 3.5.0
logstash-input-unix: 3.1.3 -> 3.1.3
logstash-integration-aws: 7.3.4 -> 7.3.4
logstash-integration-jdbc: 5.6.3 -> 5.6.3
logstash-integration-kafka: 11.8.7 -> 11.8.7
logstash-integration-logstash: 1.0.4 -> 1.0.4
logstash-integration-rabbitmq: 7.4.1 -> 7.4.1
logstash-integration-snmp: 4.2.2 -> 4.2.2
logstash-mixin-ca_trusted_fingerprint_support: 1.0.1 -> 1.0.1
logstash-mixin-deprecation_logger_support: 1.0.0 -> 1.0.0
logstash-mixin-ecs_compatibility_support: 1.3.0 -> 1.3.0
logstash-mixin-event_support: 1.0.1 -> 1.0.1
logstash-mixin-http_client: 7.5.0 -> 7.5.0
logstash-mixin-normalize_config_support: 1.0.0 -> 1.0.0
logstash-mixin-plugin_factory_support: 1.0.0 -> 1.0.0
logstash-mixin-scheduler: 1.0.1 -> 1.0.1
logstash-mixin-validator_support: 1.1.1 -> 1.1.1
logstash-output-csv: 3.0.11 -> 3.0.11
logstash-output-elasticsearch: 12.1.2 -> 12.1.2
logstash-output-email: 4.1.3 -> 4.1.3
logstash-output-file: 4.3.0 -> 4.3.0
logstash-output-graphite: 3.1.6 -> 3.1.6
logstash-output-http: 6.0.1 -> 6.0.1
logstash-output-lumberjack: 3.1.9 -> 3.1.9
logstash-output-nagios: 3.0.7 -> 3.0.7
logstash-output-null: 3.0.5 -> 3.0.5
logstash-output-pipe: 3.0.6 -> 3.0.6
logstash-output-redis: 5.2.0 -> 5.2.0
logstash-output-stdout: 3.1.4 -> 3.1.4
logstash-output-tcp: 7.0.1 -> 7.0.1
logstash-output-udp: 3.2.0 -> 3.2.0
logstash-output-webhdfs: 3.1.1 -> 3.1.1
logstash-patterns-core: 4.3.4 -> 4.3.4
---------- GENERATED CONTENT ENDS HERE ------------

### Plugins [logstash-plugin-9.4.0-changes]

**Plugin Core - 2.1.16**

404: Not Found

**Avro Codec - 3.5.0**

**Cef Codec - 6.2.8**

**Collectd Codec - 3.1.1**

**Dots Codec - 3.0.6**

**Edn Codec - 3.1.0**

**Edn_lines Codec - 3.1.0**

**Es_bulk Codec - 3.1.0**

**Fluent Codec - 3.4.3**

**Graphite Codec - 3.0.6**

**Json Codec - 3.1.1**

**Json_lines Codec - 3.2.2**

**Line Codec - 3.1.1**

**Msgpack Codec - 3.1.0**

**Multiline Codec - 3.1.2**

**Netflow Codec - 4.3.4**

**Plain Codec - 3.1.0**

**Rubydebug Codec - 3.1.0**

**Aggregate Filter - 2.11.0**

**Anonymize Filter - 3.0.7**

**Cidr Filter - 3.2.0**

**Clone Filter - 4.2.0**

**Csv Filter - 3.1.1**

**Date Filter - 3.2.0**

**De_dot Filter - 1.1.0**

**Dissect Filter - 1.3.0**

**Dns Filter - 3.2.0**

**Drop Filter - 3.0.5**

**Elastic_integration Filter - 9.3.2**

404: Not Found

**Elasticsearch Filter - 4.3.1**

**Fingerprint Filter - 3.5.0**

**Geoip Filter - 8.0.0**

**Grok Filter - 4.4.4**

**Http Filter - 2.0.0**

**Json Filter - 3.2.1**

**Kv Filter - 4.7.0**

**Memcached Filter - 1.2.0**

**Metrics Filter - 4.0.7**

**Mutate Filter - 3.6.0**

**Prune Filter - 3.0.4**

# 3.0.4
* Fixed regex to prevent Exception in sprintf call [#25](https://github.com/logstash-plugins/logstash-filter-prune/pull/25)
* Changed testing to docker [#27](https://github.com/logstash-plugins/logstash-filter-prune/pull/27)
* Added clarification in docs around whitelist_values
* Changed tests from insist to expect

* Update gemspec summary

* Fix some documentation issues

* internal: Bumped up logstash-core-plugin-api dependency to allow installation with Logstash 5.
* doc: Clarify that pruning of subfields is unsupported.

* doc: Documentation improvements.

* doc: Documentation improvements.

* internal,deps: Depend on logstash-core-plugin-api instead of logstash-core, removing the need to mass update plugins on major releases of logstash

* internal,deps: New dependency requirements for logstash-core for the 5.0 release

* internal: Plugins were updated to follow the new shutdown semantic, this mainly allows Logstash to instruct input plugins to terminate gracefully,
   instead of using Thread.raise on the plugins' threads. Ref: https://github.com/elastic/logstash/pull/3895
* internal,deps: Dependency on logstash-core update to 2.0

**Ruby Filter - 3.1.8**

**Sleep Filter - 3.0.7**

**Split Filter - 3.1.10**

**Syslog_pri Filter - 3.2.1**

**Throttle Filter - 4.0.4**

**Translate Filter - 3.5.0**

**Truncate Filter - 1.0.6**

**Urldecode Filter - 3.0.6**

**Useragent Filter - 3.3.5**

**Uuid Filter - 3.0.5**

**Xml Filter - 4.3.2**

**Azure_event_hubs Input - 1.5.5**

**Beats Input - 7.0.8**

**Couchdb_changes Input - 3.1.6**

**Dead_letter_queue Input - 2.0.2**

**Elastic_serverless_forwarder Input - 2.0.0**

**Elasticsearch Input - 5.2.1**

**Exec Input - 3.6.0**

**File Input - 4.4.7**

**Ganglia Input - 3.1.4**

**Gelf Input - 3.4.0**

**Generator Input - 3.1.0**

**Graphite Input - 3.0.6**

**Heartbeat Input - 3.1.1**

**Http Input - 4.1.7**

**Http_poller Input - 6.0.0**

**Jms Input - 3.3.1**

**Pipe Input - 3.1.0**

**Redis Input - 3.7.1**

**Stdin Input - 3.4.0**

**Syslog Input - 3.7.1**

**Tcp Input - 7.0.7**

**Twitter Input - 4.1.1**

**Udp Input - 3.5.0**

**Unix Input - 3.1.3**

**Aws Integration - 7.3.4**

**Jdbc Integration - 5.6.3**

**Kafka Integration - 11.8.7**

**Logstash Integration - 1.0.4**

**Rabbitmq Integration - 7.4.1**

**Snmp Integration - 4.2.2**

**Ca_trusted_fingerprint_support Mixin - 1.0.1**

**Deprecation_logger_support Mixin - 1.0.0**

404: Not Found

**Ecs_compatibility_support Mixin - 1.3.0**

# 1.3.0
* Feat: introduce a target check helper [#6](https://github.com/logstash-plugins/logstash-mixin-ecs_compatibility_support/pull/6) 

# 1.2.0
* Added support for resolution aliases, allowing a plugin that uses `ecs_select` to support multiple ECS versions with a single declaration.

# 1.1.0
* Added support for `ecs_select` helper, allowing plugins to declare mappings that are selected during plugin instantiation.

# 1.0.0
* Support Mixin for ensuring a plugin has an `ecs_compatibility` method that is configurable from an `ecs_compatibility` option that accepts the literal `disabled` or a v-prefixed integer representing a major ECS version (e.g., `v1`), using the implementation from Logstash core if available.

**Event_support Mixin - 1.0.1**

**Http_client Mixin - 7.5.0**

**Normalize_config_support Mixin - 1.0.0**

**Plugin_factory_support Mixin - 1.0.0**

**Scheduler Mixin - 1.0.1**

**Validator_support Mixin - 1.1.1**

**Csv Output - 3.0.11**

**Elasticsearch Output - 12.1.2**

**Email Output - 4.1.3**

**File Output - 4.3.0**

**Graphite Output - 3.1.6**

**Http Output - 6.0.1**

**Lumberjack Output - 3.1.9**

**Nagios Output - 3.0.7**

**Null Output - 3.0.5**

**Pipe Output - 3.0.6**

**Redis Output - 5.2.0**

**Stdout Output - 3.1.4**

**Tcp Output - 7.0.1**

**Udp Output - 3.2.0**

**Webhdfs Output - 3.1.1**

**Core Patterns - 4.3.4**


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