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
% **Release date:** Month day, year

% ### Features and enhancements [logstash-next-features-enhancements]
% *

% ### Fixes [logstash-next-fixes]
% *


## 9.0.0-rc1 [logstash-900-rc1-release-notes]
**Release date:** March 13, 2025

### Features and enhancements [logstash-900-rc1-features-enhancements]

* Use UBI9 as base image [#17174](https://github.com/elastic/logstash/pull/17174)
* Improve plugins remove command to support multiple plugins [#17030](https://github.com/elastic/logstash/pull/17030)
* Allow concurrent Batch deserialization [#17050](https://github.com/elastic/logstash/pull/17050)
* Upgrade filter-xml and its nokogori dependency [#17130](https://github.com/elastic/logstash/pull/17130)
* Update rack dependency to 3.1.11 [#17230](https://github.com/elastic/logstash/pull/17230)

### Fixes [logstash-900-rc1-fixes]

* Fix pqcheck and pqrepair on Windows [#17210](https://github.com/elastic/logstash/pull/17210)
* Fix empty node stats pipelines [#17185](https://github.com/elastic/logstash/pull/17185)
