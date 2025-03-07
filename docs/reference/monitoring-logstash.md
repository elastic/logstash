---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/monitoring-logstash.html
---
# Monitoring Logstash with APIs

When you run Logstash, it automatically captures runtime metrics that you can use to monitor the health and performance of your Logstash deployment.

The metrics collected by Logstash include:

* Logstash node info, like pipeline settings, OS info, and JVM info.
* Plugin info, including a list of installed plugins.
* Node stats, like JVM stats, process stats, event-related stats, and pipeline runtime stats.
* Hot threads.

You can use monitoring APIs provided by Logstash to retrieve these metrics. These APIs are available by default without requiring any extra configuration.

Alternatively, you can [configure Elastic Stack monitoring features](monitoring-logstash-legacy.md) to send
data to a monitoring cluster.

## APIs for monitoring Logstash [monitoring]

Logstash provides monitoring APIs for retrieving runtime information about Logstash:

* [Node info API](https://www.elastic.co/docs/api/doc/logstash/group/endpoint-node-info)
* [Plugins info API](https://www.elastic.co/docs/api/doc/logstash/group/endpoint-plugin-info)
* [Node stats API](https://www.elastic.co/docs/api/doc/logstash/group/endpoint-node-stats)
* [Hot threads API](https://www.elastic.co/docs/api/doc/logstash/group/endpoint-hot-threads)
* [Health report API](https://www.elastic.co/docs/api/doc/logstash/group/endpoint-health)

You can use the root resource to retrieve general information about the Logstash instance, including
the host and version.

```
curl -XGET 'localhost:9600/?pretty'
```

Example response:

```json
{
   "host": "skywalker",
   "version": "{logstash_version}",
   "http_address": "127.0.0.1:9600"
}
```

:::{note}
By default, the monitoring API attempts to bind to `tcp:9600`.
If this port is already in use by another Logstash instance, you need to launch Logstash with the `--api.http.port` flag specified to bind to a different port. For more information, go to [](running-logstash-command-line.md#command-line-flags)  
:::

## Securing the Logstash API [monitoring-api-security]

The Logstash monitoring APIs are not secured by default, but you can configure Logstash to secure them in one of several ways to meet your organization's needs.

You can enable SSL for the Logstash API by setting `api.ssl.enabled: true` in the `logstash.yml`, and providing the relevant keystore settings `api.ssl.keystore.path` and `api.ssl.keystore.password`:

```yaml
api.ssl.enabled: true
api.ssl.keystore.path: /path/to/keystore.jks
api.ssl.keystore.password: "s3cUr3p4$$w0rd"
```

The keystore must be in either jks or p12 format, and must contain both a certificate and a private key.
Connecting clients receive this certificate, allowing them to authenticate the Logstash endpoint.

You can also require HTTP Basic authentication by setting `api.auth.type: basic` in the `logstash.yml`, and providing the relevant credentials `api.auth.basic.username` and `api.auth.basic.password`:

```yaml
api.auth.type: basic
api.auth.basic.username: "logstash"
api.auth.basic.password: "s3cUreP4$$w0rD"
```

:::{note}
Usage of `Keystore` or `Environment` or variable replacements is encouraged for password-type fields to avoid storing them in plain text.
For example, specifying the value `"${HTTP_PASS}"` will resolve to the value stored in the [secure keystore's](keystore.md) `HTTP_PASS` variable if present or the same variable from the [environment](environment-variables.md).
:::

## Common options [monitoring-common-options]

The following options can be applied to all of the Logstash monitoring APIs.

### Pretty results

When appending `?pretty=true` to any request made, the JSON returned will be pretty formatted (use it for debugging only!).

### Human-readable output

:::{note}
The `human` option is supported for the hot threads API only.
When you specify `human=true`, the results are returned in plain text instead of JSON format.
The default is `false`.
:::

Statistics are returned in a format suitable for humans (for example, `"exists_time": "1h"` or `"size": "1kb"`) and for computers (for example, `"exists_time_in_millis": 3600000` or `"size_in_bytes": 1024`). The human-readable values can be turned off by adding `?human=false` to the query string. This makes sense when the stats results are being consumed by a monitoring tool, rather than intended for human consumption.  The default for the `human` flag is `false`.
