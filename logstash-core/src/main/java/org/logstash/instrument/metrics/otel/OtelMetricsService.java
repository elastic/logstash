/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *	http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package org.logstash.instrument.metrics.otel;

import io.opentelemetry.api.common.AttributeKey;
import io.opentelemetry.api.common.Attributes;
import io.opentelemetry.api.common.AttributesBuilder;
import io.opentelemetry.api.metrics.Meter;
import io.opentelemetry.api.metrics.ObservableLongCounter;
import io.opentelemetry.api.metrics.ObservableLongGauge;
import io.opentelemetry.exporter.otlp.metrics.OtlpGrpcMetricExporter;
import io.opentelemetry.exporter.otlp.http.metrics.OtlpHttpMetricExporter;
import io.opentelemetry.sdk.metrics.SdkMeterProvider;
import io.opentelemetry.sdk.metrics.export.MetricExporter;
import io.opentelemetry.sdk.metrics.export.PeriodicMetricReader;
import io.opentelemetry.sdk.resources.Resource;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.time.Duration;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.function.Supplier;

/**
 * Service that manages OpenTelemetry metrics export for Logstash.
 *
 * This service:
 * - Creates and configures the OTel SDK MeterProvider
 * - Provides methods to create metrics instruments (counters, gauges)
 * - Manages the lifecycle of the OTel exporter
 *
 * Configuration precedence (highest to lowest):
 * 1. Java system properties (e.g., -Dotel.exporter.otlp.endpoint=...)
 * 2. Environment variables (e.g., OTEL_EXPORTER_OTLP_ENDPOINT=...)
 * 3. logstash.yml settings (passed as constructor parameters)
 *
 * Supported OTel properties:
 * - otel.exporter.otlp.endpoint / OTEL_EXPORTER_OTLP_ENDPOINT
 * - otel.exporter.otlp.metrics.endpoint / OTEL_EXPORTER_OTLP_METRICS_ENDPOINT
 * - otel.exporter.otlp.protocol / OTEL_EXPORTER_OTLP_PROTOCOL
 * - otel.exporter.otlp.metrics.protocol / OTEL_EXPORTER_OTLP_METRICS_PROTOCOL
 * - otel.metric.export.interval / OTEL_METRIC_EXPORT_INTERVAL (in milliseconds)
 * - otel.exporter.otlp.headers / OTEL_EXPORTER_OTLP_HEADERS
 * - otel.resource.attributes / OTEL_RESOURCE_ATTRIBUTES
 *
 * Usage from Ruby:
 *   java_import 'org.logstash.instrument.metrics.otel.OtelMetricsService'
 *   service = OtelMetricsService.new(endpoint, node_id, node_name, interval_secs, "grpc", nil, nil)
 *   service.registerGauge("metric.name", "description", "unit", -> { get_value() }, Attributes.empty)
 */
public class OtelMetricsService {

    private static final Logger LOGGER = LogManager.getLogger(OtelMetricsService.class);

    // OTel standard configuration names (usable as system properties or environment variables)
    private static final String OTEL_EXPORTER_OTLP_ENDPOINT = "otel.exporter.otlp.endpoint";
    private static final String OTEL_EXPORTER_OTLP_METRICS_ENDPOINT = "otel.exporter.otlp.metrics.endpoint";
    private static final String OTEL_EXPORTER_OTLP_PROTOCOL = "otel.exporter.otlp.protocol";
    private static final String OTEL_EXPORTER_OTLP_METRICS_PROTOCOL = "otel.exporter.otlp.metrics.protocol";
    private static final String OTEL_METRIC_EXPORT_INTERVAL = "otel.metric.export.interval";
    private static final String OTEL_EXPORTER_OTLP_HEADERS = "otel.exporter.otlp.headers";
    private static final String OTEL_RESOURCE_ATTRIBUTES = "otel.resource.attributes";

    private final SdkMeterProvider meterProvider;
    private final Meter meter;
    // Keep references to prevent garbage collection of observable instruments
    private final Map<String, ObservableLongGauge> gauges = new ConcurrentHashMap<>();
    private final Map<String, ObservableLongCounter> observableCounters = new ConcurrentHashMap<>();

    private final String effectiveAuthorizationHeader;

    /**
     * Creates a new Otel metrics service.
     *
     * Configuration values are resolved with precedence: system properties > env vars > parameters.
     *
     * @param endpoint             OTLP endpoint from logstash.yml (e.g., "http://localhost:4317")
     * @param nodeId               Logstash node ID
     * @param nodeName             Logstash node name
     * @param intervalMs           Export interval in milliseconds from logstash.yml
     * @param protocol             "grpc" or "http" from logstash.yml
     * @param resourceAttributes   Additional resource attributes from logstash.yml (comma-separated key=value pairs)
     * @param authorizationHeader  Authorization header value from logstash.yml (e.g., "ApiKey xxx" or "Bearer xxx"), or null
     */
    public OtelMetricsService(String endpoint, String nodeId, String nodeName,
                              long intervalMs, String protocol, String resourceAttributes,
                              String authorizationHeader) {
        // Resolve configuration with precedence: system props > env vars > logstash.yml
        String effectiveEndpoint = resolveEndpoint(endpoint);
        String effectiveProtocol = resolveProtocol(protocol);
        long effectiveIntervalMs = resolveIntervalMs(intervalMs);
        String effectiveResourceAttrs = resolveResourceAttributes(resourceAttributes);
        this.effectiveAuthorizationHeader = resolveAuthorizationHeader(authorizationHeader);

        LOGGER.info("Initializing OpenTelemetry metrics export to {} (protocol: {}, interval: {}ms)",
                effectiveEndpoint, effectiveProtocol, effectiveIntervalMs);

        // Build resource attributes
        AttributesBuilder resourceAttrsBuilder = Attributes.builder()
                .put(AttributeKey.stringKey("service.name"), "logstash")
                .put(AttributeKey.stringKey("service.instance.id"), nodeId)
                .put(AttributeKey.stringKey("host.name"), nodeName);

        // Parse additional resource attributes if provided
        if (effectiveResourceAttrs != null && !effectiveResourceAttrs.isEmpty()) {
            parseResourceAttributes(effectiveResourceAttrs, resourceAttrsBuilder);
        }

        Resource resource = Resource.getDefault().merge(
                Resource.create(resourceAttrsBuilder.build())
        );

        // Create the appropriate exporter based on protocol
        MetricExporter exporter = createExporter(effectiveEndpoint, effectiveProtocol);

        // Create periodic reader
        PeriodicMetricReader metricReader = PeriodicMetricReader.builder(exporter)
                .setInterval(Duration.ofMillis(effectiveIntervalMs))
                .build();

        // Create meter provider
        this.meterProvider = SdkMeterProvider.builder()
                .setResource(resource)
                .registerMetricReader(metricReader)
                .build();

        // Get meter for creating instruments
        this.meter = meterProvider.get("logstash");

        LOGGER.info("OpenTelemetry metrics service initialized successfully");
    }

    /**
     * Resolves endpoint with precedence: system property > env var > logstash.yml.
     * Metrics-specific endpoint takes precedence over general endpoint.
     */
    private String resolveEndpoint(String logstashYmlEndpoint) {
        // First check metrics-specific endpoint
        String endpoint = getConfigValue(OTEL_EXPORTER_OTLP_METRICS_ENDPOINT, null);
        if (endpoint != null) {
            LOGGER.debug("Using metrics endpoint '{}' from {}", endpoint, getConfigSource(OTEL_EXPORTER_OTLP_METRICS_ENDPOINT));
            return endpoint;
        }

        // Then check general endpoint
        endpoint = getConfigValue(OTEL_EXPORTER_OTLP_ENDPOINT, null);
        if (endpoint != null) {
            LOGGER.debug("Using endpoint '{}' from {}", endpoint, getConfigSource(OTEL_EXPORTER_OTLP_ENDPOINT));
            return endpoint;
        }

        // Fall back to logstash.yml
        return logstashYmlEndpoint;
    }

    /**
     * Resolves protocol with precedence: system property > env var > logstash.yml.
     * Metrics-specific protocol takes precedence over general protocol.
     */
    private String resolveProtocol(String logstashYmlProtocol) {
        // First check metrics-specific protocol
        String protocol = getConfigValue(OTEL_EXPORTER_OTLP_METRICS_PROTOCOL, null);
        if (protocol != null) {
            LOGGER.debug("Using metrics protocol '{}' from {}", protocol, getConfigSource(OTEL_EXPORTER_OTLP_METRICS_PROTOCOL));
            return normalizeProtocol(protocol);
        }

        // Then check general protocol
        protocol = getConfigValue(OTEL_EXPORTER_OTLP_PROTOCOL, null);
        if (protocol != null) {
            LOGGER.debug("Using protocol '{}' from {}", protocol, getConfigSource(OTEL_EXPORTER_OTLP_PROTOCOL));
            return normalizeProtocol(protocol);
        }

        // Fall back to logstash.yml
        return logstashYmlProtocol;
    }

    /**
     * Normalizes protocol value (OTel uses "http/protobuf", we accept "http" as shorthand).
     */
    private String normalizeProtocol(String protocol) {
        if ("http/protobuf".equalsIgnoreCase(protocol)) {
            return "http";
        }
        return protocol;
    }

    /**
     * Resolves export interval with precedence: system property > env var > logstash.yml.
     * All values are in milliseconds.
     */
    private long resolveIntervalMs(long logstashYmlIntervalMs) {
        String intervalStr = getConfigValue(OTEL_METRIC_EXPORT_INTERVAL, null);
        if (intervalStr != null) {
            try {
                long intervalMs = Long.parseLong(intervalStr);
                LOGGER.debug("Using export interval from {}: {}ms", getConfigSource(OTEL_METRIC_EXPORT_INTERVAL), intervalMs);
                return intervalMs;
            } catch (NumberFormatException e) {
                LOGGER.warn("Invalid {} value '{}', using logstash.yml value", OTEL_METRIC_EXPORT_INTERVAL, intervalStr);
            }
        }

        // Fall back to logstash.yml value (already in milliseconds)
        return logstashYmlIntervalMs;
    }

    /**
     * Resolves resource attributes with precedence: system property > env var > logstash.yml.
     * Values are merged, with higher precedence overwriting lower.
     */
    private String resolveResourceAttributes(String logstashYmlAttrs) {
        String otelAttrs = getConfigValue(OTEL_RESOURCE_ATTRIBUTES, null);

        if (otelAttrs != null && logstashYmlAttrs != null && !logstashYmlAttrs.isEmpty()) {
            // Merge: OTel attrs take precedence, append logstash.yml attrs
            String merged = otelAttrs + "," + logstashYmlAttrs;
            LOGGER.debug("Merging resource attributes '{}' from {} with logstash.yml", otelAttrs, getConfigSource(OTEL_RESOURCE_ATTRIBUTES));
            return merged;
        } else if (otelAttrs != null) {
            LOGGER.debug("Using resource attributes '{}' from {}", otelAttrs, getConfigSource(OTEL_RESOURCE_ATTRIBUTES));
            return otelAttrs;
        }

        return logstashYmlAttrs;
    }

    /**
     * Resolves authorization header with precedence: system property > env var > logstash.yml.
     * Extracts Authorization header from otel.exporter.otlp.headers if present.
     */
    private String resolveAuthorizationHeader(String logstashYmlAuthHeader) {
        String headers = getConfigValue(OTEL_EXPORTER_OTLP_HEADERS, null);
        if (headers != null) {
            // Parse headers format: "key1=value1,key2=value2"
            for (String header : headers.split(",")) {
                String[] parts = header.split("=", 2);
                if (parts.length == 2 && "Authorization".equalsIgnoreCase(parts[0].trim())) {
                    LOGGER.debug("Using Authorization header from {} (value redacted)", getConfigSource(OTEL_EXPORTER_OTLP_HEADERS));
                    return parts[1].trim();
                }
            }
        }

        return logstashYmlAuthHeader;
    }

    /**
     * Gets a configuration value with precedence: system property > environment variable.
     */
    static String getConfigValue(String propertyName, String defaultValue) {
        // 1. Check system property
        String value = System.getProperty(propertyName);
        if (value != null && !value.isEmpty()) {
            return value;
        }

        // 2. Check environment variable (convert property name to env var format)
        String envVarName = propertyToEnvVar(propertyName);
        value = System.getenv(envVarName);
        if (value != null && !value.isEmpty()) {
            return value;
        }

        return defaultValue;
    }

    /**
     * Converts a system property name to environment variable format.
     * e.g., "otel.exporter.otlp.endpoint" -> "OTEL_EXPORTER_OTLP_ENDPOINT"
     */
    static String propertyToEnvVar(String propertyName) {
        return propertyName.toUpperCase().replace('.', '_').replace('-', '_');
    }

    /**
     * Returns the source of a configuration value for logging purposes.
     */
    private String getConfigSource(String propertyName) {
        if (System.getProperty(propertyName) != null) {
            return "system property " + propertyName;
        }
        String envVarName = propertyToEnvVar(propertyName);
        if (System.getenv(envVarName) != null) {
            return "environment variable " + envVarName;
        }
        return "logstash.yml";
    }

    private MetricExporter createExporter(String endpoint, String protocol) {
        if ("http".equalsIgnoreCase(protocol)) {
            var builder = OtlpHttpMetricExporter.builder()
                    .setEndpoint(normalizeHttpEndpoint(endpoint))
                    .setTimeout(Duration.ofSeconds(10));
            if (effectiveAuthorizationHeader != null && !effectiveAuthorizationHeader.isEmpty()) {
                builder.addHeader("Authorization", effectiveAuthorizationHeader);
            }
            return builder.build();
        } else {
            // Default to gRPC
            var builder = OtlpGrpcMetricExporter.builder()
                    .setEndpoint(endpoint)
                    .setTimeout(Duration.ofSeconds(10));
            if (effectiveAuthorizationHeader != null && !effectiveAuthorizationHeader.isEmpty()) {
                builder.addHeader("Authorization", effectiveAuthorizationHeader);
            }
            return builder.build();
        }
    }

    /**
     * Normalizes HTTP endpoint by appending /v1/metrics if not already present.
     * This allows users to specify either the base URL or the full path.
     */
    static String normalizeHttpEndpoint(String endpoint) {
        return endpoint.endsWith("/v1/metrics") ? endpoint : endpoint + "/v1/metrics";
    }

    // Package-private and static for testing
    static void parseResourceAttributes(String attributes, AttributesBuilder builder) {
        for (String pair : attributes.split(",")) {
            String trimmedPair = pair.trim();
            if (trimmedPair.isEmpty()) {
                continue;
            }
            String[] keyValue = trimmedPair.split("=", 2);
            if (keyValue.length == 2) {
                builder.put(AttributeKey.stringKey(keyValue[0].trim()), keyValue[1].trim());
            } else {
                LOGGER.warn("Ignoring malformed resource attribute '{}': expected format 'key=value'", trimmedPair);
            }
        }
    }

    /**
     * Registers an observable gauge with a callback.
     * The callback is invoked by the SDK when metrics are exported.
     *
     * @param name          Metric name
     * @param description   Human-readable description
     * @param unit          Unit of measurement
     * @param valueSupplier Callback that returns the current value
     * @param attributes    Attributes/labels for this gauge
     */
    public void registerGauge(String name, String description, String unit,
                              Supplier<Long> valueSupplier, Attributes attributes) {
        ObservableLongGauge gauge = meter.gaugeBuilder(name)
                .setDescription(description)
                .setUnit(unit)
                .ofLongs()
                .buildWithCallback(measurement -> {
                    try {
                        Long value = valueSupplier.get();
                        if (value != null) {
                            measurement.record(value, attributes);
                        }
                    } catch (Exception e) {
                        LOGGER.debug("Error collecting gauge {}: {}", name, e.getMessage());
                    }
                });
        gauges.put(name, gauge);
    }

    /**
     * Registers an observable counter with a callback.
     * Observable counters are for monotonically increasing values where you observe
     * the cumulative total (e.g., CPU time consumed, total bytes read from disk).
     * The SDK automatically computes deltas between observations.
     *
     * @param name          Metric name
     * @param description   Human-readable description
     * @param unit          Unit of measurement
     * @param valueSupplier Callback that returns the current cumulative value
     * @param attributes    Attributes/labels for this counter
     */
    public void registerObservableCounter(String name, String description, String unit,
                                          Supplier<Long> valueSupplier, Attributes attributes) {
        ObservableLongCounter counter = meter.counterBuilder(name)
                .setDescription(description)
                .setUnit(unit)
                .buildWithCallback(measurement -> {
                    try {
                        Long value = valueSupplier.get();
                        if (value != null && value >= 0) {
                            measurement.record(value, attributes);
                        }
                    } catch (Exception e) {
                        LOGGER.debug("Error collecting observable counter {}: {}", name, e.getMessage());
                    }
                });
        observableCounters.put(name, counter);
    }

    /**
     * Forces an immediate flush of pending metrics.
     */
    public void flush() {
        if (meterProvider != null) {
            meterProvider.forceFlush();
        }
    }

    /**
     * Shuts down the service and releases resources.
     * Flushes any pending metrics before closing.
     */
    public void shutdown() {
        LOGGER.info("Shutting down OpenTelemetry metrics service");
        if (meterProvider != null) {
            // Wait for any in-flight exports to complete before closing
            try {
                meterProvider.forceFlush().join(5, java.util.concurrent.TimeUnit.SECONDS);
            } catch (Exception e) {
                LOGGER.debug("Error during final metrics flush: {}", e.getMessage());
            }
            meterProvider.close();
        }
        LOGGER.info("OpenTelemetry metrics service shut down");
    }
}
