---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/logstash-monitoring-ui.html
---

# Monitoring UI [logstash-monitoring-ui]

Use the {{stack}} {{monitor-features}} to view metrics and gain insight into how your {{ls}} deployment is running. In the overview dashboard, you can see all events received and sent by Logstash, plus info about memory usage and uptime:

:::{image} ../images/overviewstats.png
:alt: Logstash monitoring overview dashboard in Kibana
:::

Then you can drill down to see stats about a specific node:

:::{image} ../images/nodestats.png
:alt: Logstash monitoring node stats dashboard in Kibana
:::

::::{note}
A {{ls}} node is considered unique based on its persistent UUID, which is written to the [`path.data`](/reference/logstash-settings-file.md) directory when the node starts.
::::


Before you can use the monitoring UI, [configure Logstash monitoring](/reference/monitoring-logstash-legacy.md).

For information about using the Monitoring UI, see [{{monitoring}} in {{kib}}](docs-content://deploy-manage/monitor/monitoring-data/visualizing-monitoring-data.md).

