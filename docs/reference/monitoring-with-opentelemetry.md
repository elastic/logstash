---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/monitoring-with-opentelemetry.html
applies_to:
  stack: preview
---

# Monitoring Logstash with OpenTelemetry

Logstash can export metrics to any OpenTelemetry Protocol (OTLP) compatible backend, enabling integration with observability platforms like Elastic, Prometheus, etc.

## Overview

The OpenTelemetry metrics exporter sends Logstash runtime metrics directly via OTLP (OpenTelemetry Protocol). This provides a standardized way to collect and export metrics without requiring an intermediate collector, though you can also route metrics through an OpenTelemetry Collector if needed.

## Configuration

To enable OpenTelemetry metrics export, add the following settings to your `logstash.yml` file:

```yaml
otel.metrics.enabled: true
otel.metrics.endpoint: "http://localhost:4317"
otel.metrics.interval: 10
otel.metrics.protocol: "grpc"
```

### Settings

| Setting | Description | Default |
| --- | --- | --- |
| `otel.metrics.enabled` | Enable or disable OpenTelemetry metrics export. | `false` |
| `otel.metrics.endpoint` | The OTLP endpoint URL. For gRPC, typically port 4317. For HTTP, typically port 4318. | `http://localhost:4317` |
| `otel.metrics.interval` | Export interval in seconds. Controls how frequently metrics are sent to the endpoint. | `10` |
| `otel.metrics.protocol` | Protocol to use for OTLP export. Valid values are `grpc` or `http`. | `grpc` |
| `otel.metrics.authorization_header` | Authorization header for authenticated endpoints. Examples: `ApiKey xxx` or `Bearer xxx`. | *N/A* |
| `otel.resource.attributes` | Additional resource attributes as comma-separated key=value pairs. Example: `environment=production,cluster=us-west`. | *N/A* |

## Sending metrics to Elastic Cloud

To send metrics directly to Elastic Cloud's native OTLP endpoint:

1. Get your Elastic Cloud OTLP endpoint from your deployment's APM integration settings
2. Create an API key with appropriate permissions
3. Configure Logstash:

```yaml
otel.metrics.enabled: true
otel.metrics.endpoint: "https://your-deployment.apm.us-central1.gcp.cloud.es.io:443"
otel.metrics.protocol: "http"
otel.metrics.authorization_header: "ApiKey your-base64-encoded-api-key"
```

## Sending metrics to an OpenTelemetry Collector

You can also send metrics to an OpenTelemetry Collector, which can then forward them to multiple backends:

```yaml
otel.metrics.enabled: true
otel.metrics.endpoint: "http://otel-collector:4317"
otel.metrics.protocol: "grpc"
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

### Cgroup metrics (Linux only)

These metrics are available when running on Linux with cgroups enabled (e.g., in containers).

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
| `service.name` | Always set to `logstash` |
| `service.instance.id` | The Logstash node ID |
| `service.version` | The Logstash version |
| `host.name` | The configured node name |

Additional resource attributes can be added using the `otel.resource.attributes` setting.

## Viewing metrics in Kibana

When sending metrics to Elastic Cloud via the native OTLP endpoint, metrics are stored in APM data streams (`.ds-metrics-apm.app.logstash-*`). You can view them in:

1. **Observability > APM > Services** - Find your Logstash service
2. **Observability > Metrics Explorer** - Query metrics directly
3. **Discover** - Search the `metrics-apm.app.logstash-*` data view

When using an OpenTelemetry Collector with the Elasticsearch exporter, create a data view matching your configured index pattern (e.g., `metrics-otel-*`).

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

**Authentication errors**

Ensure the `otel.metrics.authorization_header` is correctly formatted:
- For API keys: `ApiKey base64-encoded-key`
- For Bearer tokens: `Bearer your-token`

**Metrics not appearing**

- Check that `otel.metrics.enabled` is set to `true`
- Verify the export interval hasn't been set too high
- Check Logstash logs for export errors
