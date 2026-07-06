---
applies_to:
  stack: preview 9.5.0+
  serverless: preview
---

# Monitoring Logstash with OpenTelemetry

Logstash can export metrics to any OpenTelemetry Protocol (OTLP) compatible backend, like Elastic, Prometheus, and others.

## Overview

The OpenTelemetry metrics exporter sends Logstash runtime metrics directly using the OpenTelemetry Protocol (OTLP). This provides a standardized way to collect and export metrics without requiring an intermediate collector, though you can also route metrics through an OpenTelemetry Collector if needed.

## Configuration

To enable OpenTelemetry metrics export, add the following settings to your `logstash.yml` file:

```yaml
otel.metrics.enabled: true
otel.exporter.otlp.endpoint: "http://localhost:4317"
otel.metric.export.interval: "10s"
otel.exporter.otlp.protocol: "grpc"
```

### Settings

| Setting | Description | Default |
| --- | --- | --- |
| `otel.metrics.enabled` | Enable or disable OpenTelemetry metrics export. | `false` |
| `otel.exporter.otlp.endpoint` | OTLP metrics endpoint URL. For gRPC, the default port is 4317. For HTTP the default port is 4318. When using the HTTP protocol, `/v1/metrics` is automatically appended if not already present, and the default port (80 for `http://`, 443 for `https://`) is added if no port is specified. | `http://localhost:4317` |
| `otel.metric.export.interval` | Export interval with time unit. Controls how frequently metrics are sent to the endpoint. For example: `10s` or `1m`. | `"10s"` |
| `otel.exporter.otlp.protocol` | Protocol to use for OTLP export. Valid values are `grpc` and `http`. | `grpc` |
| `otel.exporter.otlp.headers` | HTTP headers as comma-separated `key=value` pairs to include in every OTLP request. Example: `Authorization=ApiKey xxx` or `Authorization=Bearer xxx,X-Custom=foo`. | Not applicable |
| `otel.resource.attributes` | Additional resource attributes as comma-separated key=value pairs. Example: `environment=production,cluster=us-west`. | Not applicable |
| `otel.service.name` | Service name for metrics. | `logstash` |
| `otel.exporter.otlp.certificate` | Path to a PEM-encoded trusted CA certificate for verifying the OTLP endpoint's TLS certificate. Required when the endpoint uses a self-signed or private CA. | Not applicable |
| `otel.exporter.otlp.client.key` | Path to a PEM-encoded client private key for mutual TLS (mTLS). Must be set together with `otel.exporter.otlp.client.certificate`. | Not applicable |
| `otel.exporter.otlp.client.certificate` | Path to a PEM-encoded client certificate for mutual TLS (mTLS). Must be set together with `otel.exporter.otlp.client.key`. | Not applicable |

### Configuration precedence

OpenTelemetry settings can be configured using Java system properties or by editing the `logstash.yml` file. The resolution order is:

1. **Java system properties** (highest priority). For example, `-Dotel.service.name=my-service`
2. **logstash.yml** (lowest priority)

Supported system properties and their Logstash setting equivalents:

| System Property | logstash.yml Setting |
| --- | --- |
| `otel.service.name` | `otel.service.name` |
| `otel.exporter.otlp.endpoint` | `otel.exporter.otlp.endpoint` |
| `otel.exporter.otlp.protocol` | `otel.exporter.otlp.protocol` |
| `otel.metric.export.interval` | `otel.metric.export.interval` |
| `otel.resource.attributes` | `otel.resource.attributes` |
| `otel.exporter.otlp.headers` | `otel.exporter.otlp.headers` |
| `otel.exporter.otlp.certificate` | `otel.exporter.otlp.certificate` |
| `otel.exporter.otlp.client.key` | `otel.exporter.otlp.client.key` |
| `otel.exporter.otlp.client.certificate` | `otel.exporter.otlp.client.certificate` |

## Sending metrics to Elastic Cloud

To send metrics directly to the Elastic Cloud Managed OTLP Endpoint:

1. Get your Elastic Cloud OTLP endpoint from your deployment's settings.
2. Create an API key with appropriate permissions.
3. Configure Logstash:

```yaml
otel.metrics.enabled: true
otel.exporter.otlp.endpoint: "https://your-deployment.apm.us-central1.gcp.cloud.es.io:443"
otel.exporter.otlp.protocol: "http"
otel.exporter.otlp.headers: "Authorization=ApiKey your-base64-encoded-api-key"
```

## Sending metrics to an OpenTelemetry Collector

You can also send metrics to an OpenTelemetry Collector, which can then forward them to multiple backends:

```yaml
otel.metrics.enabled: true
otel.exporter.otlp.endpoint: "http://otel-collector:4317"
otel.exporter.otlp.protocol: "grpc"
```

Example OpenTelemetry Collector configuration to forward to Elasticsearch:

```yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

processors:
  batch:

exporters:
  elasticsearch:
    endpoints: ["https://your-elasticsearch-host:9200"]
    api_key: "your-api-key"
    mapping:
      mode: otel

service:
  pipelines:
    metrics:
      receivers: [otlp]
      processors: [batch]
      exporters: [elasticsearch]
```

## Exported metrics

Logstash exports the following metrics via OpenTelemetry:

### Global metrics

| Metric name | Type | Unit | Description |
| --- | --- | --- | --- |
| `logstash.events.in` | Counter | `{event}` | Total events received across all pipelines |
| `logstash.events.out` | Counter | `{event}` | Total events output across all pipelines |
| `logstash.events.filtered` | Counter | `{event}` | Total events filtered across all pipelines |
| `logstash.queue.events` | Gauge | `{event}` | Total events currently in queues |

### Pipeline metrics

Pipeline metrics include a `pipeline.id` attribute to identify the pipeline.

| Metric name | Type | Unit | Description |
| --- | --- | --- | --- |
| `logstash.pipeline.events.in` | Counter | `{event}` | Events received by pipeline |
| `logstash.pipeline.events.out` | Counter | `{event}` | Events output by pipeline |
| `logstash.pipeline.events.filtered` | Counter | `{event}` | Events filtered by pipeline |
| `logstash.pipeline.queue.events` | Gauge | `{event}` | Events in pipeline queue |

### Persistent queue metrics

These metrics are available when using persistent queues (`queue.type: persisted`).

| Metric name | Type | Unit | Description |
| --- | --- | --- | --- |
| `logstash.pipeline.queue.capacity.page_capacity` | Gauge | `By` | Size of each queue page in bytes |
| `logstash.pipeline.queue.capacity.max_size` | Gauge | `By` | Maximum queue size limit in bytes |
| `logstash.pipeline.queue.capacity.max_unread_events` | Gauge | `{event}` | Maximum unread events allowed |
| `logstash.pipeline.queue.capacity.size` | Gauge | `By` | Current persisted queue size in bytes |
| `logstash.pipeline.queue.data.free_space` | Gauge | `By` | Free disk space where queue is stored |

### Dead letter queue metrics

| Metric name | Type | Unit | Description |
| --- | --- | --- | --- |
| `logstash.pipeline.dlq.queue_size` | Gauge | `By` | Current dead letter queue size in bytes |
| `logstash.pipeline.dlq.max_queue_size` | Gauge | `By` | Maximum DLQ size limit in bytes |
| `logstash.pipeline.dlq.dropped_events` | Gauge | `{event}` | Events dropped when DLQ is full |
| `logstash.pipeline.dlq.expired_events` | Gauge | `{event}` | Events expired and removed from DLQ |

### Plugin metrics

Plugin metrics include `pipeline.id`, `plugin.type`, and `plugin.id` attributes.

| Metric name | Type | Unit | Description |
| --- | --- | --- | --- |
| `logstash.plugin.events.in` | Counter | `{event}` | Events received by plugin |
| `logstash.plugin.events.out` | Counter | `{event}` | Events output by plugin |
| `logstash.plugin.events.duration` | Counter | `ms` | Time spent processing events |

### JVM metrics

| Metric name | Type | Unit | Description |
| --- | --- | --- | --- |
| `logstash.jvm.uptime` | Gauge | `ms` | JVM uptime since start |
| `logstash.jvm.mem.heap.used` | Gauge | `By` | Heap memory currently used |
| `logstash.jvm.mem.heap.committed` | Gauge | `By` | Heap memory committed to the JVM |
| `logstash.jvm.mem.heap.max` | Gauge | `By` | Maximum heap memory available |
| `logstash.jvm.mem.heap.used_percent` | Gauge | `%` | Heap memory used as a percentage of max |
| `logstash.jvm.mem.non_heap.used` | Gauge | `By` | Non-heap memory currently used |
| `logstash.jvm.mem.non_heap.committed` | Gauge | `By` | Non-heap memory committed to the JVM |
| `logstash.jvm.gc.collection_count` | Counter | `{collection}` | Number of GC collections. Includes a `gc.generation` attribute (`young` or `old`). |
| `logstash.jvm.gc.collection_time` | Counter | `ms` | Total time spent in GC. Includes a `gc.generation` attribute (`young` or `old`). |
| `logstash.jvm.threads.count` | Gauge | `{thread}` | Current number of JVM threads |
| `logstash.jvm.threads.peak_count` | Gauge | `{thread}` | Peak number of JVM threads since start |
| `logstash.jvm.process.open_file_descriptors` | Gauge | `{file_descriptor}` | Number of open file descriptors |
| `logstash.jvm.process.max_file_descriptors` | Gauge | `{file_descriptor}` | Maximum number of file descriptors |
| `logstash.jvm.process.cpu.percent` | Gauge | `%` | Process CPU usage |
| `logstash.jvm.process.cpu.total` | Counter | `ms` | Total CPU time consumed by the process |

### Cgroup metrics (Linux only)

These metrics are available when running on Linux with cgroups enabled, for example in containers.

| Metric name | Type | Unit | Description |
| --- | --- | --- | --- |
| `logstash.os.cgroup.cpuacct.usage` | Counter | `ns` | Total CPU time consumed |
| `logstash.os.cgroup.cpu.cfs_period` | Gauge | `us` | CFS scheduling period |
| `logstash.os.cgroup.cpu.cfs_quota` | Gauge | `us` | CFS scheduling quota |
| `logstash.os.cgroup.cpu.stat.elapsed_periods` | Counter | `{period}` | Number of elapsed CFS periods |
| `logstash.os.cgroup.cpu.stat.nr_times_throttled` | Counter | `{occurrence}` | Number of times throttled |
| `logstash.os.cgroup.cpu.stat.time_throttled` | Counter | `ns` | Total time throttled |

## Resource attributes

The following resource attributes are automatically added to all metrics:

| Attribute | Description |
| --- | --- |
| `service.name` | Defaults to `logstash`; configurable via `otel.service.name` |
| `service.instance.id` | The Logstash node ID |
| `host.name` | The Logstash node name (`node.name`) |
| `data_stream.dataset` | Always `logstash`; the Elastic ingest endpoint appends `.otel`, resulting in `logstash.otel` |

Additional resource attributes can be added using the `otel.resource.attributes` setting.

## Viewing metrics in Kibana

When sending metrics to Elastic Cloud via the native OTLP endpoint, metrics are stored in APM data streams (`.ds-metrics-apm.app.logstash-*`). You can view them in:

1. Find your Logstash service under **Observability → APM → Services**.
2. Query metrics directly in **Observability → Metrics Explorer**.
3. Search the `metrics-apm.app.logstash-*` data view using **Discover**.

When using an OpenTelemetry Collector with the Elasticsearch exporter, create a data view matching your configured index pattern. For example, `metrics-otel-*`.

## Troubleshooting

### Enable debug logging

To see detailed OpenTelemetry SDK logs, add the following to `config/log4j2.properties`:

```properties
logger.otel.name = io.opentelemetry
logger.otel.level = debug
```

### Common issues

**Connection refused errors**

Verify the endpoint is accessible:
- For gRPC (default): Port 4317
- For HTTP: Port 4318 with `/v1/metrics` path automatically appended
- If no port is specified, defaults are used: 80 for `http://`, 443 for `https://`

**Authentication errors**

Ensure the `otel.exporter.otlp.headers` is correctly formatted:
- For API keys: `ApiKey base64-encoded-key`
- For Bearer tokens: `Bearer your-token`

**Metrics not appearing**

- Check that `otel.metrics.enabled` is set to `true`
- Verify the export interval hasn't been set too high
- Check Logstash logs for export errors
