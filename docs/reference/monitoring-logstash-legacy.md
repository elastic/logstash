---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/configuring-logstash.html
---

# Monitoring Logstash (Legacy) [configuring-logstash]

Use the {{stack}} {{monitor-features}} to gain insight into the health of {{ls}} instances running in your environment. For an introduction to monitoring your Elastic stack, see [Monitoring a cluster](docs-content://deploy-manage/monitor.md) in the [Elasticsearch Reference](docs-content://get-started/index.md). Then, make sure that monitoring is enabled on your {{es}} cluster.

These options for collecting {{ls}} metrics for stack monitoring have been available for a while:

* [{{metricbeat}} collection](/reference/monitoring-with-metricbeat.md). Metricbeat collects monitoring data from your {{ls}} instance and sends it directly to your monitoring cluster. The benefit of Metricbeat collection is that the monitoring agent remains active even if the {{ls}} instance does not.
* [Legacy collection (deprecated)](/reference/monitoring-internal-collection-legacy.md). Legacy collectors send monitoring data to your production cluster.

For more features, dependability, and easier management, consider using:

* [{{agent}} collection for Stack Monitoring](/reference/monitoring-with-elastic-agent.md). {{agent}} collects monitoring data from your {{ls}} instance and sends it directly to your monitoring cluster, and shows the data in {{ls}} Dashboards. The benefit of {{agent}} collection is that the monitoring agent remains active even if the {{ls}} instance does not, you can manage all your monitoring agents from a central location in {{fleet}}.






