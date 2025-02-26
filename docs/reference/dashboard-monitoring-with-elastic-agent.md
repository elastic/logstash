---
navigation_title: "Collect monitoring data for dashboards"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/dashboard-monitoring-with-elastic-agent.html
---

# Collect {{ls}} monitoring data for dashboards [dashboard-monitoring-with-elastic-agent]


{{agent}} collects monitoring data from your {{ls}} instance, sends it directly to your monitoring cluster, and shows the data in {{ls}} dashboards.

You can enroll {{agent}} in [{{fleet}}](docs-content://reference/ingestion-tools/fleet/install-fleet-managed-elastic-agent.md) for management from a central location, or you can run [{{agent}} standalone](docs-content://reference/ingestion-tools/fleet/install-standalone-elastic-agent.md).

**Prerequisites**

Complete these steps as you prepare to collect and ship monitoring data for dashboards:

::::{dropdown} Disable default collection of {{ls}} monitoring metrics
:name: disable-default-db

Set `monitoring.enabled` to `false` in logstash.yml to disable default collection:

```yaml
monitoring.enabled: false
```

::::


::::{dropdown} Specify the target cluster_uuid (optional)
:name: define-cluster__uuid-db

To bind the metrics of {{ls}} to a specific cluster, optionally define the `monitoring.cluster_uuid` in the configuration file (logstash.yml):

```yaml
monitoring.cluster_uuid: PRODUCTION_ES_CLUSTER_UUID
```

::::


::::{dropdown} Create a monitoring user (standalone agent only)
:name: create-user-db

Create a user on the production cluster that has the `remote_monitoring_collector` [built-in role](elasticsearch://docs/reference/elasticsearch/roles.md).

::::



## Install and configure {{agent}} [install-and-configure-db]

Install and configure {{agent}} to collect {{ls}} monitoring data for dashboards. We’ll walk you through the process in these steps:

* [Add the {{agent}} {{ls}} integration to monitor host logs and metrics](#add-logstash-integration-ead)
* [Install and run an {{agent}} on your machine](#add-agent-to-fleet-ead)
* [View assets](#view-assets-ead)
* [Monitor {{ls}} logs and metrics](#view-data-dashboard)

Check out [Installing {{agent}}](docs-content://reference/ingestion-tools/fleet/install-elastic-agents.md) in the *Fleet and Elastic Agent Guide* for more info.


### Add the {{agent}} {{ls}} integration to monitor host logs and metrics [add-logstash-integration-ead]

1. Go to the {{kib}} home page, and click **Add integrations**.

    :::{image} ../images/kibana-home.png
    :alt: {{kib}} home page
    :class: screenshot
    :::

2. In the query bar, search for **{{ls}}** and select the integration to see more details.
3. Click **Add {{ls}}**.
4. Configure the integration name and add a description (optional).
5. Configure the integration to collect logs.

    * Make sure that **Logs** is turned on if you want to collect logs from your {{ls}} instance. Be sure that the required settings are correctly configured.
    * Under **Logs**, modify the log paths to match your {{ls}} environment.

6. Configure the integration to collect metrics.

    * Make sure that **Metrics (Technical Preview)** is turned on, and **Metrics (Stack Monitoring)** is turned off.
    * Under **Metrics (Technical Preview)**, make sure the {{ls}} URL setting points to your {{ls}} instance URLs.<br> By default, the integration collects {{ls}} monitoring metrics from `https://localhost:9600`. If that host and port number are not correct, update the `Logstash URL` setting. If you configured {{ls}} to use encrypted communications and/or a username and password, you must access it via HTTPS, and expand the **Advanced Settings** options, and fill in with the appropriate values for your {{ls}} instance.

7. Click **Save and continue**.<br> This step takes a minute or two to complete. When it’s done, you’ll have an agent policy that contains a system integration policy for the configuration you just specified.
8. In the popup, click **Add {{agent}} to your hosts** to open the **Add agent** flyout.

    ::::{tip}
    If you accidentally close the popup, go to **{{fleet}} > Agents** and click **Add agent**.
    ::::



## Install and run an {{agent}} on your machine [add-agent-to-fleet-ead]

The **Add agent** flyout has two options: **Enroll in {{fleet}}** and **Run standalone**. Enrolling agents in {{fleet}} (default) provides a centralized management tool in {{kib}}, reducing management overhead.

:::::::{tab-set}

::::::{tab-item} Fleet-managed
1. When the **Add Agent flyout** appears, stay on the **Enroll in fleet** tab.
2. Skip the **Select enrollment token** step. The enrollment token you need is already selected.

    ::::{note}
    The enrollment token is specific to the {{agent}} policy that you just created. When you run the command to enroll the agent in {{fleet}}, you will pass in the enrollment token.
    ::::

3. Download, install, and enroll the {{agent}} on your host by selecting your host operating system and following the **Install {{agent}} on your host** step.

It takes about a minute for {{agent}} to enroll in {{fleet}}, download the configuration specified in the policy you just created, and start collecting data.
::::::

::::::{tab-item} Run standalone
1. When the **Add Agent flyout** appears, navigate to the **Run standalone** tab.
2. Configure the agent. Follow the instructions in **Install Elastic Agent on your host**.
3. After unpacking the binary, replace the `elastic-agent.yml` file with that supplied in the Add Agent flyout on the "Run standalone" tab, replacing the values of `ES_USERNAME` and `ES_PASSWORD` appropriately.
4. Run `sudo ./elastic-agent install`
::::::

:::::::

## View assets [view-assets-ead]

After you have confirmed enrollment and data is coming in,  click **View assets** to access dashboards related to the {{ls}} integration.

For traditional Stack Monitoring UI, the dashboards marked **[Logs {{ls}}]** are used to visualize the logs produced by your {{ls}} instances, with those marked **[Metrics {{ls}}]** for the technical preview metrics dashboards. These are populated with data only if you selected the **Metrics (Technical Preview)** checkbox.

:::{image} ../images/integration-assets-dashboards.png
:alt: Integration assets
:class: screenshot
:::

A number of dashboards are included to view {{ls}} as a whole, and dashboards that allow you to drill-down into how {{ls}} is performing on a node, pipeline and plugin basis.


## Monitor {{ls}} logs and metrics [view-data-dashboard]

From the list of assets, open the **[Metrics {{ls}}] {{ls}} overview** dashboard to view overall performance. Then follow the navigation panel to further drill down into {{ls}} performance.

:::{image} ../images/integration-dashboard-overview.png
:alt: The {{ls}} Overview dashboard in {{kib}} with various metrics from your monitored {ls}
:class: screenshot
:::

You can hover over any visualization to adjust its settings, or click the **Edit** button to make changes to the dashboard. To learn more, refer to [Dashboard and visualizations](docs-content://explore-analyze/dashboards.md).
