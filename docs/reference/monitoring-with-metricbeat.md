---
navigation_title: "{{metricbeat}} collection"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/monitoring-with-metricbeat.html
---

# Collect {{ls}} monitoring data with {{metricbeat}} [monitoring-with-metricbeat]


You can use {{metricbeat}} to collect data about {{ls}} and ship it to the monitoring cluster. The benefit of Metricbeat collection is that the monitoring agent remains active even if the {{ls}} instance does not.

This step requires [{{es}} with {{metricbeat}} monitoring setup](docs-content://deploy-manage/monitor/stack-monitoring/collecting-monitoring-data-with-metricbeat.md).

To collect and ship monitoring data:

1. [Disable default collection of monitoring metrics](#disable-default)
2. [Specify the target `cluster_uuid`](#define-cluster__uuid)
3. [Install and configure {{metricbeat}} to collect monitoring data](#configure-metricbeat)

Want to use {{agent}} instead? Refer to [Collect monitoring data for stack monitoring](/reference/monitoring-with-elastic-agent.md).


## Disable default collection of {{ls}} monitoring metrics [disable-default]

Set the `monitoring.enabled` to `false` in logstash.yml to disable to default monitoring:

```yaml
monitoring.enabled: false
```


## Determine target Elasticsearch cluster [define-cluster__uuid]

You will need to determine which Elasticsearch cluster that {{ls}} will bind metrics to in the Stack Monitoring UI by specifying the `cluster_uuid`. When pipelines contain [{{es}} output plugins](/reference/plugins-outputs-elasticsearch.md), the `cluster_uuid` is automatically calculated, and the metrics should be bound without any additional settings.

To override automatic values, or if your pipeline does not contain any [{{es}} output plugins](/reference/plugins-outputs-elasticsearch.md), you can bind the metrics of {{ls}} to a specific cluster, by defining the target cluster in the `monitoring.cluster_uuid` setting. in the configuration file (logstash.yml):

```yaml
monitoring.cluster_uuid: PRODUCTION_ES_CLUSTER_UUID
```

Refer to [{{es}} cluster stats page](https://www.elastic.co/docs/api/doc/elasticsearch/operation/operation-cluster-stats) to figure out how to get your cluster `cluster_uuid`.


## Install and configure {{metricbeat}} [configure-metricbeat]

1. [Install {{metricbeat}}](beats://docs/reference/metricbeat/metricbeat-installation-configuration.md) on the same server as {{ls}}.
2. Enable the `logstash-xpack` module in {{metricbeat}}.<br>

    To enable the default configuration in the {{metricbeat}} `modules.d` directory, run:

    **deb or rpm:**<br>

    ```sh
    metricbeat modules enable logstash-xpack
    ```

    **linux or mac:**

    ```sh
    ./metricbeat modules enable logstash-xpack
    ```

    **win:**

    ```sh
    PS > .\metricbeat.exe modules enable logstash-xpack
    ```

    For more information, see [Specify which modules to run](beats://docs/reference/metricbeat/configuration-metricbeat.md) and [beat module](beats://docs/reference/metricbeat/metricbeat-module-beat.md).

3. Configure the `logstash-xpack` module in {{metricbeat}}.<br>

    The `modules.d/logstash-xpack.yml` file contains these settings:

    ```yaml
      - module: logstash
        metricsets:
          - node
          - node_stats
        period: 10s
        hosts: ["localhost:9600"]
        #username: "user"
        #password: "secret"
        xpack.enabled: true
    ```

    Set the `hosts`, `username`, and `password` to authenticate with {{ls}}. For other module settings, it’s recommended that you accept the defaults.

    By default, the module collects {{ls}} monitoring data from `localhost:9600`.

    To monitor multiple {{ls}} instances, specify a list of hosts, for example:

    ```yaml
    hosts: ["http://localhost:9601","http://localhost:9602","http://localhost:9603"]
    ```

    **Elastic security.** The Elastic {{security-features}} are enabled by default. You must provide a user ID and password so that {{metricbeat}} can collect metrics successfully:

    1. Create a user on the production cluster that has the `remote_monitoring_collector` [built-in role](elasticsearch://docs/reference/elasticsearch/roles.md).
    2. Add the `username` and `password` settings to the module configuration file (`logstash-xpack.yml`).

4. Optional: Disable the system module in the {{metricbeat}}.

    By default, the [system module](beats://docs/reference/metricbeat/metricbeat-module-system.md) is enabled. The information it collects, however, is not shown on the **Stack Monitoring** page in {{kib}}. Unless you want to use that information for other purposes, run the following command:

    ```sh
    metricbeat modules disable system
    ```

5. Identify where to send the monitoring data.<br>

    ::::{tip}
    In production environments, we strongly recommend using a separate cluster (referred to as the *monitoring cluster*) to store the data. Using a separate monitoring cluster prevents production cluster outages from impacting your ability to access your monitoring data. It also prevents monitoring activities from impacting the performance of your production cluster.
    ::::


    For example, specify the {{es}} output information in the {{metricbeat}} configuration file (`metricbeat.yml`):

    ```yaml
    output.elasticsearch:
      # Array of hosts to connect to.
      hosts: ["http://es-mon-1:9200", "http://es-mon2:9200"] <1>

      # Optional protocol and basic auth credentials.
      #protocol: "https"
      #username: "elastic"
      #password: "changeme"
    ```

    1. In this example, the data is stored on a monitoring cluster with nodes `es-mon-1` and `es-mon-2`.


    If you configured the monitoring cluster to use encrypted communications, you must access it via HTTPS. For example, use a `hosts` setting like `https://es-mon-1:9200`.

    ::::{important}
    The {{es}} {{monitor-features}} use ingest pipelines, therefore the cluster that stores the monitoring data must have at least one ingest node.
    ::::


    **Elastic security.** The Elastic {{security-features}} are enabled by default. You must provide a user ID and password so that {{metricbeat}} can send metrics successfully:

    1. Create a user on the monitoring cluster that has the `remote_monitoring_agent` [built-in role](elasticsearch://docs/reference/elasticsearch/roles.md). Alternatively, use the `remote_monitoring_user` [built-in user](docs-content://deploy-manage/users-roles/cluster-or-deployment-auth/built-in-users.md).

        ::::{tip}
        If you’re using index lifecycle management, the remote monitoring user requires additional privileges to create and read indices. For more information, see `<<feature-roles>>`.
        ::::

    2. Add the `username` and `password` settings to the {{es}} output information in the {{metricbeat}} configuration file.

    For more information about these configuration options, see [Configure the {{es}} output](beats://docs/reference/metricbeat/elasticsearch-output.md).

6. [Start {{metricbeat}}](beats://docs/reference/metricbeat/metricbeat-starting.md) to begin collecting monitoring data.
7. [View the monitoring data in {{kib}}](docs-content://deploy-manage/monitor/stack-monitoring/kibana-monitoring-data.md).

Your monitoring setup is complete.
