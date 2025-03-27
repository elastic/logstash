---
navigation_title: "Legacy collection (deprecated)"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/monitoring-internal-collection-legacy.html
---

# Collect {{ls}} monitoring data using legacy collectors [monitoring-internal-collection-legacy]


::::{warning}
Deprecated in 7.9.0.
::::


::::{note}
Starting from version 9.0, legacy internal collection is behind a feature flag and is turned off by default. Set `xpack.monitoring.allow_legacy_collection` to `true` to allow access to the feature.
::::


Using [{{agent}} for monitoring](/reference/monitoring-logstash-with-elastic-agent.md) is a better alternative for most {{ls}} deployments.

## Components for legacy collection [_components_for_legacy_collection]

Monitoring {{ls}} with legacy collection uses these components:

* [Collectors](#logstash-monitoring-collectors-legacy)
* [Output](#logstash-monitoring-output-legacy)

These pieces live outside of the default Logstash pipeline in a dedicated monitoring pipeline. This configuration ensures that all data and processing has a minimal impact on ordinary Logstash processing. Existing Logstash features, such as the [`elasticsearch` output](logstash-docs-md://lsr/plugins-outputs-elasticsearch.md), can be reused to benefit from its retry policies.

::::{note}
The `elasticsearch` output that is used for monitoring {{ls}} is configured exclusively through settings found in `logstash.yml`. It is not configured by using anything from the Logstash configurations that might also be using their own separate `elasticsearch` outputs.
::::


The production {{es}} cluster should be configured to receive {{ls}} monitoring data. This configuration enables the production {{es}} cluster to add metadata (for example, its cluster UUID) to the Logstash monitoring data and then route it to the monitoring clusters. For more information  about typical monitoring architectures, see  [How monitoring works](docs-content://deploy-manage/monitor/stack-monitoring.md) in the [Elasticsearch Reference](docs-content://get-started/index.md).


#### Collectors [logstash-monitoring-collectors-legacy]

Collectors, as their name implies, collect things. In monitoring for Logstash, collectors are just [Inputs](/reference/how-logstash-works.md) in the same way that ordinary Logstash configurations provide inputs.

Like monitoring for {{es}}, each collector can create zero or more monitoring documents. As it is currently implemented, each Logstash node runs two types of collectors: one for node stats and one for pipeline stats.

| Collector | Data Types | Description |
| --- | --- | --- |
| Node Stats | `logstash_stats` | Gathers details about the running node, such as memory utilization and CPUusage (for example, `GET /_stats`).<br>This runs on every Logstash node with monitoring enabled. One commonfailure is that Logstash directories are copied with their `path.data` directoryincluded (`./data` by default), which copies the persistent UUID of the Logstashnode along with it. As a result, it generally appears that one or more Logstashnodes are failing to collect monitoring data, when in fact they are all reallymisreporting as the *same* Logstash node. Re-use `path.data` directories onlywhen upgrading Logstash, such that upgraded nodes replace the previous versions. |
| Pipeline Stats | `logstash_state` | Gathers details about the node’s running pipelines, which powers theMonitoring Pipeline UI. |

Per collection interval, which defaults to 10 seconds (`10s`), each collector is run. The failure of an individual collector does not impact any other collector. Each collector, as an ordinary Logstash input, creates a separate Logstash event in its isolated monitoring pipeline. The Logstash output then sends the data.

The collection interval can be configured dynamically and you can also disable data collection. For more information about the configuration options for the collectors, see [Monitoring Settings](#monitoring-settings-legacy).

::::{warning}
Unlike {{es}} and {{kib}} monitoring, there is no `xpack.monitoring.collection.enabled` setting on Logstash. You must use the `xpack.monitoring.enabled` setting to enable and disable data collection.
::::


If gaps exist in the monitoring charts in {{kib}}, it is typically because either a collector failed or the monitoring cluster did not receive the data (for example, it was being restarted). In the event that a collector fails, a logged error should exist on the node that attempted to perform the collection.


### Output [logstash-monitoring-output-legacy]

Like all Logstash pipelines, the purpose of the dedicated monitoring pipeline is to send events to outputs. In the case of monitoring for Logstash, the output is always an `elasticsearch` output. However, unlike ordinary Logstash pipelines, the output is configured within the `logstash.yml` settings file via the `xpack.monitoring.elasticsearch.*` settings.

Other than its unique manner of configuration, this `elasticsearch` output behaves like all `elasticsearch` outputs, including its ability to pause data collection when issues exist with the output.

::::{important}
It is critical that all Logstash nodes share the same setup. Otherwise, monitoring data might be routed in different ways or to different places.
::::



#### Default Configuration [logstash-monitoring-default-legacy]

If a Logstash node does not explicitly define a monitoring output setting, the following default configuration is used:

```yaml
xpack.monitoring.elasticsearch.hosts: [ "http://localhost:9200" ]
```

All data produced by monitoring for Logstash is indexed in the monitoring cluster by using the `.monitoring-logstash` template, which is managed by the [exporters](docs-content://deploy-manage/monitor/stack-monitoring/es-monitoring-exporters.md) within {{es}}.

If you are working with a cluster that has {{security}} enabled, extra steps are necessary to properly configure Logstash. For more information, see [*Monitoring {{ls}} (legacy)*](/reference/monitoring-logstash-legacy.md).

::::{important}
When discussing security relative to the `elasticsearch` output, it is critical to remember that all users are managed on the production cluster, which is identified in the `xpack.monitoring.elasticsearch.hosts` setting. This is particularly important to remember when you move from development environments to production environments, where you often have dedicated monitoring clusters.
::::


For more information about the configuration options for the output, see [Monitoring Settings](#monitoring-settings-legacy).


## Configure {{ls}} monitoring with legacy collectors [configure-internal-collectors-legacy]


To monitor Logstash nodes:

1. Specify where to send monitoring data. This cluster is often referred to as the *production cluster*. For examples of typical monitoring architectures, see [How monitoring works](docs-content://deploy-manage/monitor/stack-monitoring.md).

    ::::{important}
    To visualize Logstash as part of the Elastic Stack (as shown in Step 6), send metrics to your *production* cluster. Sending metrics to a dedicated monitoring cluster will show the Logstash metrics under the *monitoring* cluster.
    ::::

2. Verify that the `xpack.monitoring.allow_legacy_collection` and `xpack.monitoring.collection.enabled` settings are `true` on the production cluster. If that setting is `false`, the collection of monitoring data is disabled in {{es}} and data is ignored from all other sources.
3. Configure your Logstash nodes to send metrics by setting `xpack.monitoring.enabled` to `true` and specifying the destination {{es}} node(s) as `xpack.monitoring.elasticsearch.hosts` in `logstash.yml`. If {{security-features}} are enabled, you also need to specify the credentials for the [built-in `logstash_system` user](docs-content://deploy-manage/users-roles/cluster-or-deployment-auth/built-in-users.md). For more information about these settings, see [Monitoring Settings](#monitoring-settings-legacy).

    ```yaml
    xpack.monitoring.allow_legacy_collection: true
    xpack.monitoring.enabled: true
    xpack.monitoring.elasticsearch.hosts: ["http://es-prod-node-1:9200", "http://es-prod-node-2:9200"] <1>
    xpack.monitoring.elasticsearch.username: "logstash_system"
    xpack.monitoring.elasticsearch.password: "changeme"
    ```

    1. If SSL/TLS is enabled on the production cluster, you must connect through HTTPS. As of v5.2.1, you can specify multiple Elasticsearch hosts as an array as well as specifying a single host as a string. If multiple URLs are specified, Logstash can round-robin requests to these production nodes.

4. If SSL/TLS is enabled on the production {{es}} cluster, specify the trusted CA certificates that will be used to verify the identity of the nodes in the cluster.

    To add a CA certificate to a Logstash node’s trusted certificates, you can specify the location of the PEM encoded certificate with the `certificate_authority` setting:

    ```yaml
    xpack.monitoring.elasticsearch.ssl.certificate_authority: /path/to/ca.crt
    ```

    To add a CA without having it loaded on disk, you can specify a hex-encoded SHA 256 fingerprint of the DER-formatted CA with the `ca_trusted_fingerprint` setting:

    ```yaml
    xpack.monitoring.elasticsearch.ssl.ca_trusted_fingerprint: 2cfe62e474fb381cc7773c84044c28c9785ac5d1940325f942a3d736508de640
    ```

    ::::{note}
    A self-secured Elasticsearch cluster will provide the fingerprint of its CA to the console during setup.

    You can also get the SHA256 fingerprint of an Elasticsearch’s CA using the `openssl` command-line utility on the Elasticsearch host:

    ```shell
    openssl x509 -fingerprint -sha256 -in $ES_HOME/config/certs/http_ca.crt
    ```

    ::::


    Alternatively, you can configure trusted certificates using a truststore (a Java Keystore file that contains the certificates):

    ```yaml
    xpack.monitoring.elasticsearch.ssl.truststore.path: /path/to/file
    xpack.monitoring.elasticsearch.ssl.truststore.password: password
    ```

    Also, optionally, you can set up client certificate using a keystore (a Java Keystore file that contains the certificate) or using a certificate and key file pair:

    ```yaml
    xpack.monitoring.elasticsearch.ssl.keystore.path: /path/to/file
    xpack.monitoring.elasticsearch.ssl.keystore.password: password
    ```

    ```yaml
    xpack.monitoring.elasticsearch.ssl.certificate: /path/to/certificate
    xpack.monitoring.elasticsearch.ssl.key: /path/to/key
    ```

    Set sniffing to `true` to enable discovery of other nodes of the {{es}} cluster. It defaults to `false`.

    ```yaml
    xpack.monitoring.elasticsearch.sniffing: false
    ```

5. Restart your Logstash nodes.
6. To verify your monitoring configuration, point your web browser at your {{kib}} host, and select **Stack Monitoring** from the side navigation. If this is an initial setup, select **set up with self monitoring** and click **Turn on monitoring**. Metrics reported from your Logstash nodes should be visible in the Logstash section. When security is enabled, to view the monitoring dashboards you must log in to {{kib}} as a user who has the `kibana_user` and `monitoring_user` roles.

    :::{image} images/monitoring-ui.png
    :alt: Monitoring
    :::



## Monitoring settings for legacy collection [monitoring-settings-legacy]


You can set the following `xpack.monitoring` settings in `logstash.yml` to control how monitoring data is collected from your Logstash nodes. However, the defaults work best in most circumstances. For more information about configuring Logstash, see [logstash.yml](/reference/logstash-settings-file.md).

### General monitoring settings [monitoring-general-settings-legacy]

`xpack.monitoring.enabled`
:   Monitoring is disabled by default. Set to `true` to enable {{xpack}} monitoring.

`xpack.monitoring.elasticsearch.hosts`
:   The {{es}} instances that you want to ship your Logstash metrics to. This might be the same {{es}} instance specified in the `outputs` section in your Logstash configuration, or a different one. This is **not** the URL of your dedicated monitoring cluster. Even if you are using a dedicated monitoring cluster, the Logstash metrics must be routed through your production cluster. You can specify a single host as a string, or specify multiple hosts as an array. Defaults to `http://localhost:9200`.

::::{note}
If your Elasticsearch cluster is configured with dedicated master-eligible nodes, Logstash metrics should *not* be routed to these nodes, as doing so can create resource contention and impact the stability of the Elasticsearch cluster. Therefore, do not include such nodes in `xpack.monitoring.elasticsearch.hosts`.
::::


`xpack.monitoring.elasticsearch.proxy`
:   The monitoring {{es}} instance and monitored Logstash can be separated by a proxy. To enable Logstash to connect to a proxied {{es}}, set this value to the URI of the intermediate proxy using the standard URI format, `<protocol>://<host>` for example `http://192.168.1.1`. An empty string is treated as if proxy was not set.

`xpack.monitoring.elasticsearch.username` and `xpack.monitoring.elasticsearch.password`
:   If your {{es}} is protected with basic authentication, these settings provide the username and password that the Logstash instance uses to authenticate for shipping monitoring data.


### Monitoring collection settings [monitoring-collection-settings-legacy]

`xpack.monitoring.collection.interval`
:   Controls how often data samples are collected and shipped on the Logstash side. Defaults to `10s`. If you modify the collection interval, set the `xpack.monitoring.min_interval_seconds` option in `kibana.yml` to the same value.


### Monitoring TLS/SSL settings [monitoring-ssl-settings-legacy]

You can configure the following Transport Layer Security (TLS) or Secure Sockets Layer (SSL) settings. For more information, see [Configuring credentials for {{ls}} monitoring](/reference/secure-connection.md#ls-monitoring-user).

`xpack.monitoring.elasticsearch.ssl.ca_trusted_fingerprint`
:   Optional setting that enables you to specify the hex-encoded SHA-256 fingerprint of the certificate authority for your {{es}} instance.

::::{note}
A self-secured Elasticsearch cluster will provide the fingerprint of its CA to the console during setup.

You can also get the SHA256 fingerprint of an Elasticsearch’s CA using the `openssl` command-line utility on the Elasticsearch host:

```shell
openssl x509 -fingerprint -sha256 -in $ES_HOME/config/certs/http_ca.crt
```

::::


`xpack.monitoring.elasticsearch.ssl.certificate_authority`
:   Optional setting that enables you to specify a path to the `.pem` file for the certificate authority for your {{es}} instance.

`xpack.monitoring.elasticsearch.ssl.truststore.path`
:   Optional settings that provide the paths to the Java keystore (JKS) to validate the server’s certificate.

`xpack.monitoring.elasticsearch.ssl.truststore.password`
:   Optional settings that provide the password to the truststore.

`xpack.monitoring.elasticsearch.ssl.keystore.path`
:   Optional settings that provide the paths to the Java keystore (JKS) to validate the client’s certificate.

`xpack.monitoring.elasticsearch.ssl.keystore.password`
:   Optional settings that provide the password to the keystore.

`xpack.monitoring.elasticsearch.ssl.certificate`
:   Optional setting that provides the path to an SSL certificate to use to authenticate the client. This certificate should be an OpenSSL-style X.509 certificate file.

::::{note}
This setting can be used only if `xpack.monitoring.elasticsearch.ssl.key` is set.
::::


`xpack.monitoring.elasticsearch.ssl.key`
:   Optional setting that provides the path to an OpenSSL-style RSA private key that corresponds to the `xpack.monitoring.elasticsearch.ssl.certificate`.

::::{note}
This setting can be used only if `xpack.monitoring.elasticsearch.ssl.certificate` is set.
::::


`xpack.monitoring.elasticsearch.ssl.verification_mode`
:   Option to validate the server’s certificate. Defaults to `full`. To disable, set to `none`. Disabling this severely compromises security.

`xpack.monitoring.elasticsearch.ssl.cipher_suites`
:   Optional setting that provides the list of cipher suites to use, listed by priorities. Supported cipher suites vary depending on the Java and protocol versions.


### Additional settings [monitoring-additional-settings-legacy]

`xpack.monitoring.elasticsearch.cloud_id`
:   If you’re using {{es}} in {{ecloud}}, you should specify the identifier here. This setting is an alternative to `xpack.monitoring.elasticsearch.hosts`. If `cloud_id` is configured, `xpack.monitoring.elasticsearch.hosts` should not be used. The {{es}} instances that you want to ship your Logstash metrics to. This might be the same {{es}} instance specified in the `outputs` section in your Logstash configuration, or a different one.

`xpack.monitoring.elasticsearch.cloud_auth`
:   If you’re using {{es}} in {{ecloud}}, you can set your auth credentials here. This setting is an alternative to both `xpack.monitoring.elasticsearch.username` and `xpack.monitoring.elasticsearch.password`. If `cloud_auth` is configured, those settings should not be used.

`xpack.monitoring.elasticsearch.api_key`
:   Authenticate using an Elasticsearch API key. Note that this option also requires using SSL.

The API key Format is `id:api_key` where `id` and `api_key` are as returned by the Elasticsearch [Create API key API](https://www.elastic.co/docs/api/doc/elasticsearch/operation/operation-security-create-api-key).
