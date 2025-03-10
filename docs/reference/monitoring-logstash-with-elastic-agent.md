---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/monitoring-with-ea.html
---

# Monitoring Logstash with Elastic Agent [monitoring-with-ea]

You can use {{agent}} to collect data about {{ls}} and ship it to the monitoring cluster. When you use {{agent}} collection, the monitoring agent remains active even if the {{ls}} instance does not. Plus you have the option to manage all of your monitoring agents from a central location in {{fleet}}.

{{agent}} gives you a single, unified way to add monitoring for logs, metrics, and other types of data to a host. Each agent has a single policy you can update to add integrations for new data sources, security protections, and more.

You can use {{agent}} to collect {{ls}} monitoring data on:

* [{{ecloud}} or self-managed dashboards](/reference/dashboard-monitoring-with-elastic-agent.md).<br> {{agent}} collects monitoring data from your {{ls}} instance, sends it directly to your monitoring cluster, and shows the data in {{ls}} dashboards. {{ls}} dashboards include an extended range of metrics, including plugin drilldowns, and plugin specific dashboards for the dissect filter, the grok filter, and the elasticsearch output.
* [{{ecloud}} dashboards (serverless)](/reference/serverless-monitoring-with-elastic-agent.md).<br> {{agent}} collects monitoring data from your {{ls}} instance, sends it to [Elastic serverless](docs-content://deploy-manage/deploy/elastic-cloud/serverless.md), and shows the data in {{ls}} dashboards in [Elastic Observability](docs-content://solutions/observability.md). {{ls}} dashboards include an extended range of metrics, including plugin drilldowns, and plugin specific dashboards for the dissect filter, the grok filter, and the elasticsearch output.
* [{{stack}} monitoring](/reference/monitoring-with-elastic-agent.md).<br> Use the Elastic Stack monitoring features to gain insight into the health of {{ls}} instances running in your environment.




