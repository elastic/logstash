---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/upgrading-logstash.html
---

# Upgrading Logstash [upgrading-logstash]

::::{important}
Before upgrading Logstash:

* Consult the [breaking changes](/release-notes/breaking-changes.md) docs.
* Read the [*Release Notes*](/release-notes/index.md).
* Test upgrades in a development environment before upgrading your production cluster.

While upgrading Logstash:

* If you use monitoring, you must re-use the data directory when you upgrade Logstash. Otherwise, the Logstash node is assigned a new persistent UUID and becomes a new node in the monitoring data.

::::


If you’re upgrading other products in the stack, also read the [Elastic Stack Installation and Upgrade Guide](docs-content://deploy-manage/index.md).

See the following topics for information about upgrading Logstash:

* [Upgrading using package managers](/reference/upgrading-using-package-managers.md)
* [Upgrading using a direct download](/reference/upgrading-using-direct-download.md)
* [Upgrading between minor versions](/reference/upgrading-minor-versions.md)
* [Upgrading Logstash to 9.0](https://www.elastic.co/guide/en/logstash/master/upgrading-logstash-9.0.html)


## When to upgrade [_when_to_upgrade]

Fresh installations can and should start with the same version across the Elastic Stack.

Elasticsearch 9.0 does not require Logstash 9.0. An Elasticsearch 9.0 cluster will happily receive data from earlier versions of Logstash via the default HTTP communication layer. This provides some flexibility to decide when to upgrade Logstash relative to an Elasticsearch upgrade. It may or may not be convenient for you to upgrade them together, and it is not required to be done at the same time as long as Elasticsearch is upgraded first. However, there are special plugin cases for example, if your pipeline includes [elastic_integration filter](/reference/plugins-filters-elastic_integration.md) plugin. See [when `elastic_integration` is in {{ls}} pipeline](#upgrading-when-elastic_integration-in-pipeline) section for details.

You should upgrade in a timely manner to get the performance improvements that come with Logstash 9.0, but do so in the way that makes the most sense for your environment.


## When not to upgrade [_when_not_to_upgrade]

If any Logstash plugin that you require is not compatible with Logstash 9.0, then you should wait until it is ready before upgrading.

Although we make great efforts to ensure compatibility, Logstash 9.0 is not completely backwards compatible. As noted in the Elastic Stack upgrade guide, you should not upgrade Logstash 9.0 before you upgrade Elasticsearch 9.0. This is both practical and because some Logstash 9.0 plugins may attempt to use features of Elasticsearch 9.0 that did not exist in earlier versions.

For example, if you attempt to send the 8.x template to a cluster before Elasticsearch 9.0, then  all indexing likely fail. If you use your own custom template with Logstash, then this issue can be ignored.

Another example is when your pipeline utilizes the [`elastic_integration` filter](/reference/plugins-filters-elastic_integration.md) plugin. In such cases, the plugin may encounter issues loading and executing deprecated integrations or features that have been removed in newer versions. This can lead to disruptions in your pipeline’s functionality, especially if your workflow relies on these outdated components. For a comprehensive understanding of how to handle such scenarios and ensure compatibility, refer to the [when `elastic_integration` is in {{ls}} pipeline](#upgrading-when-elastic_integration-in-pipeline) section in this documentation.


## When `elastic_integration` is in {{ls}} pipeline [upgrading-when-elastic_integration-in-pipeline]

[elastic_integration filter](/reference/plugins-filters-elastic_integration.md) plugin requires a special attention due to its dependencies on various components of the stack such as {{es}}, {{kib}} and {{ls}}. Any updates, deprecations, or changes in the stack products can directly impact the functionality of the plugin.

**When upgrading {{es}}**

This plugin is compiled with a specific version of {{es}} and embeds {{es}} Ingest Node components that match the `major.minor` stack version. Therefore, we recommend using a plugin version that aligns with the `major.minor` version of your stack.

If the versions do not match, the plugin may encounter issues such as failing to load or execute pipelines. For example, if your {{es}} version is newer than the plugin, the plugin may not support new features introduced in the updated {{es}} version. Conversely, if your {{es}} version is older, the plugin may rely on features that have been deprecated or removed in your {{es}} version.

**When upgrading {{kib}}**

When you upgrade {{kib}}, {{kib}} downloads the latest version of the integrations through [Elastic Package Registry](docs-content://reference/ingestion-tools/fleet/index.md#package-registry-intro). As part of the upgrade process, you will also have the opportunity to review and upgrade your currently installed integrations to their latest versions. However, we strongly recommend upgrading the [elastic_integration filter](/reference/plugins-filters-elastic_integration.md) plugin before upgrading {{kib}} and {{es}}. This is because [elastic_integration filter](/reference/plugins-filters-elastic_integration.md) plugin pulls and processes the ingest pipelines associated with the installed integrations. These pipelines are then executed using the {{es}} Ingest Node components that the plugin was compiled with. If {{es}} or {{es}} is upgraded first, there is a risk of incompatibility between the plugin’s ingest componenets and the newer versions of {{es}}'s Ingest Node features or {{kib}}'s integration definitions.

**When upgrading {{ls}}**

This plugin is by default embedded in {{ls}} core. When you upgrade {{ls}}, new version of the plugin is installed. The plugin is backward compatible accross {{ls}} 8.x versions. However, if you are considering to upgrade {{ls}} only (not the plugin), there are exceptions cases, such as JDK compatibility which require matching certain {{ls}} versions. We recommend visiting [elastic_integration plugin requirements](/reference/plugins-filters-elastic_integration.md#plugins-filters-elastic_integration-requirements) guide considering the {{ls}} version you are upgrading to.





