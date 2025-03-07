---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/upgrading-logstash-9.0.html
---

# Upgrading Logstash to 9.0 [upgrading-logstash-9.0]

Before upgrading Logstash:

* Read the [*Release Notes*](/release-notes/index.md).
* Read the [breaking changes](/release-notes/breaking-changes.md) docs.

    There you can find info on these topics and more:

    * [Changes to SSL settings in {{ls}} plugins](/release-notes/breaking-changes.md#ssl-settings-9.0)


If you are installing Logstash with other components in the Elastic Stack, also see the [Elastic Stack installation and upgrade documentation](docs-content://deploy-manage/index.md).

::::{note}
Upgrading between non-consecutive major versions (7.x to 9.x, for example) is not supported. We recommend that you upgrade to 8.17, and then upgrade to 9.0.
::::



## Upgrade to {{ls}} 8.17 before upgrading to 9.0 [upgrade-to-previous]

If you haven’t already, upgrade to version 8.17 before you upgrade to 9.0. If you’re using other products in the {{stack}}, upgrade {{ls}} as part of the [{{stack}} upgrade process](docs-content://deploy-manage/upgrade/deployment-or-cluster.md).

::::{tip}
Upgrading to {{ls}} 8.17 gives you a head-start on new 9.0 features. This step helps reduce risk and makes roll backs easier if you hit a snag.
::::


