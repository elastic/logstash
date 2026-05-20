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

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.time.Duration;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CopyOnWriteArrayList;
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
 * 2. logstash.yml settings (passed as constructor parameters)
 *
 * Supported OTel system properties:
 * - otel.exporter.otlp.endpoint
 * - otel.exporter.otlp.protocol
 * - otel.metric.export.interval (in milliseconds)
 * - otel.exporter.otlp.headers (key=value,key=value format, e.g. Authorization=ApiKey xxx)
 * - otel.resource.attributes
 * - otel.service.name
 * - otel.exporter.otlp.certificate
 * - otel.exporter.otlp.client.key
 * - otel.exporter.otlp.client.certificate
 */
public class OtelMetricsService {

    private static final Logger LOGGER = LogManager.getLogger(OtelMetricsService.class);

    // OTel standard configuration names (usable as system properties)
    private static final String OTEL_SERVICE_NAME = "otel.service.name";
    private static final String OTEL_EXPORTER_OTLP_ENDPOINT = "otel.exporter.otlp.endpoint";
    private static final String OTEL_EXPORTER_OTLP_PROTOCOL = "otel.exporter.otlp.protocol";
    private static final String OTEL_METRIC_EXPORT_INTERVAL = "otel.metric.export.interval";
    private static final String OTEL_EXPORTER_OTLP_HEADERS = "otel.exporter.otlp.headers";
    private static final String OTEL_RESOURCE_ATTRIBUTES = "otel.resource.attributes";
    private static final String OTEL_EXPORTER_OTLP_CERTIFICATE = "otel.exporter.otlp.certificate";
    private static final String OTEL_EXPORTER_OTLP_CLIENT_KEY = "otel.exporter.otlp.client.key";
    private static final String OTEL_EXPORTER_OTLP_CLIENT_CERTIFICATE = "otel.exporter.otlp.client.certificate";

    private static final String DEFAULT_SERVICE_NAME = "logstash";
    private static final String DEFAULT_DATASET = "logstash";

    private final SdkMeterProvider meterProvider;
    private final Meter meter;
    // Strong references to prevent garbage collection of observable instruments.
    // Multiple pipelines and plugins register instruments with the same metric name but
    // different attributes, so a List is used rather than a name-keyed map to avoid
    // overwriting earlier registrations and making them eligible for GC.
    private final List<ObservableLongGauge> gauges = new CopyOnWriteArrayList<>();
    private final List<ObservableLongCounter> observableCounters = new CopyOnWriteArrayList<>();

    private final Map<String, String> effectiveHeaders;
    private final byte[] effectiveTrustedCertsPem;
    private final byte[] effectiveClientKeyPem;
    private final byte[] effectiveClientCertPem;

    /**
     * Creates a new Otel metrics service from the given configuration.
     *
     * Configuration values from {@code config} are resolved with precedence:
     * system properties > config values.
     *
     * @param config  service configuration built via {@link OtelMetricsConfig#builder}
     */
    public OtelMetricsService(OtelMetricsConfig config) {
        // Resolve configuration with precedence: system props > config values
        String effectiveEndpoint = resolveEndpoint(config.getEndpoint());
        String effectiveProtocol = resolveProtocol(config.getProtocol());
        long effectiveIntervalMs = resolveIntervalMs(config.getIntervalMs());
        String effectiveResourceAttrs = resolveResourceAttributes(config.getResourceAttributes());
        this.effectiveHeaders = resolveHeaders(config.getHeaders());
        String effectiveServiceName = resolveServiceName(config.getServiceName());
        this.effectiveTrustedCertsPem = readPemFile(resolveFilePath(OTEL_EXPORTER_OTLP_CERTIFICATE, config.getCertificatePath()));
        this.effectiveClientKeyPem = readPemFile(resolveFilePath(OTEL_EXPORTER_OTLP_CLIENT_KEY, config.getClientKeyPath()));
        this.effectiveClientCertPem = readPemFile(resolveFilePath(OTEL_EXPORTER_OTLP_CLIENT_CERTIFICATE, config.getClientCertificatePath()));

        LOGGER.info("Initializing OpenTelemetry metrics export to {} (protocol: {}, interval: {}ms)",
                effectiveEndpoint, effectiveProtocol, effectiveIntervalMs);

        // Build resource attributes
        AttributesBuilder resourceAttrsBuilder = Attributes.builder()
                .put(AttributeKey.stringKey("service.name"), effectiveServiceName)
                .put(AttributeKey.stringKey("service.instance.id"), config.getNodeId())
                .put(AttributeKey.stringKey("host.name"), config.getNodeName())
                .put(AttributeKey.stringKey("data_stream.dataset"), DEFAULT_DATASET);

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
     * Resolves service name with precedence: system property > logstash.yml > default.
     */
    static String resolveServiceName(String logstashYmlServiceName) {
        String serviceName = getSystemProperty(OTEL_SERVICE_NAME, null);
        if (serviceName != null) {
            LOGGER.debug("Using service name '{}' from system property {}", serviceName, OTEL_SERVICE_NAME);
            return serviceName;
        }

        // Fall back to logstash.yml if provided
        if (logstashYmlServiceName != null && !logstashYmlServiceName.isEmpty()) {
            return logstashYmlServiceName;
        }

        // Fall back to default
        return DEFAULT_SERVICE_NAME;
    }

    /**
     * Resolves endpoint with precedence: system property > logstash.yml.
     */
    private String resolveEndpoint(String logstashYmlEndpoint) {
        String endpoint = getSystemProperty(OTEL_EXPORTER_OTLP_ENDPOINT, null);
        if (endpoint != null) {
            LOGGER.debug("Using metrics endpoint '{}' from system property {}", endpoint, OTEL_EXPORTER_OTLP_ENDPOINT);
            return endpoint;
        }
        return logstashYmlEndpoint;
    }

    /**
     * Resolves protocol with precedence: system property > logstash.yml.
     */
    private String resolveProtocol(String logstashYmlProtocol) {
        String protocol = getSystemProperty(OTEL_EXPORTER_OTLP_PROTOCOL, null);
        if (protocol != null) {
            LOGGER.debug("Using protocol '{}' from system property {}", protocol, OTEL_EXPORTER_OTLP_PROTOCOL);
            return normalizeProtocol(protocol);
        }
        return logstashYmlProtocol;
    }

    /**
     * Normalizes protocol value (OTel uses "http/protobuf", we accept "http" as shorthand).
     */
    static String normalizeProtocol(String protocol) {
        if ("http/protobuf".equalsIgnoreCase(protocol)) {
            return "http";
        }
        return protocol;
    }

    /**
     * Resolves export interval with precedence: system property > logstash.yml.
     * All values are in milliseconds.
     */
    private long resolveIntervalMs(long logstashYmlIntervalMs) {
        String intervalStr = getSystemProperty(OTEL_METRIC_EXPORT_INTERVAL, null);
        if (intervalStr != null) {
            try {
                long intervalMs = Long.parseLong(intervalStr);
                LOGGER.debug("Using export interval from system property {}: {}ms", OTEL_METRIC_EXPORT_INTERVAL, intervalMs);
                return intervalMs;
            } catch (NumberFormatException e) {
                LOGGER.warn("Invalid {} value '{}', using logstash.yml value", OTEL_METRIC_EXPORT_INTERVAL, intervalStr);
            }
        }

        // Fall back to logstash.yml value (already in milliseconds)
        return logstashYmlIntervalMs;
    }

    /**
     * Resolves resource attributes with precedence: system property > logstash.yml.
     */
    private String resolveResourceAttributes(String logstashYmlAttrs) {
        String sysPropAttrs = getSystemProperty(OTEL_RESOURCE_ATTRIBUTES, null);
        if (sysPropAttrs != null) {
            LOGGER.debug("Using resource attributes '{}' from system property {}", sysPropAttrs, OTEL_RESOURCE_ATTRIBUTES);
            return sysPropAttrs;
        }
        return logstashYmlAttrs;
    }

    /**
     * Resolves headers with precedence: system property > logstash.yml.
     * Both sources use the same {@code key=value,key=value} format.
     */
    private Map<String, String> resolveHeaders(String logstashYmlHeaders) {
        String sysPropHeaders = getSystemProperty(OTEL_EXPORTER_OTLP_HEADERS, null);
        if (sysPropHeaders != null) {
            LOGGER.debug("Using headers from system property {} (values redacted)", OTEL_EXPORTER_OTLP_HEADERS);
            return parseHeaders(sysPropHeaders);
        }
        if (logstashYmlHeaders != null && !logstashYmlHeaders.isEmpty()) {
            return parseHeaders(logstashYmlHeaders);
        }
        return Collections.emptyMap();
    }

    /**
     * Parses a {@code key=value,key=value} header string into a map.
     * Values may contain {@code =} (split is limited to 2 parts).
     * Empty entries are silently skipped; malformed entries log a warning and are skipped.
     * Package-private for testing.
     */
    static Map<String, String> parseHeaders(String headers) {
        Map<String, String> result = new LinkedHashMap<>();
        for (String pair : headers.split(",")) {
            String trimmedPair = pair.trim();
            if (trimmedPair.isEmpty()) {
                continue;
            }
            String[] keyValue = trimmedPair.split("=", 2);
            if (keyValue.length == 2) {
                result.put(keyValue[0].trim(), keyValue[1].trim());
            } else {
                LOGGER.warn("Ignoring malformed header '{}': expected format 'key=value'", trimmedPair);
            }
        }
        return result;
    }


    /**
     * Resolves a file path with precedence: system property > logstash.yml.
     */
    private String resolveFilePath(String systemPropertyName, String logstashYmlPath) {
        String sysPropPath = getSystemProperty(systemPropertyName, null);
        if (sysPropPath != null) {
            LOGGER.debug("Using '{}' from system property {}", sysPropPath, systemPropertyName);
            return sysPropPath;
        }
        return logstashYmlPath;
    }

    /**
     * Reads PEM file bytes from the given path, returning null if path is null or empty.
     * Throws at startup rather than silently ignoring misconfiguration.
     * Package-private for testing.
     */
    static byte[] readPemFile(String path) {
        if (path == null || path.isEmpty()) {
            return null;
        }
        try {
            return Files.readAllBytes(Paths.get(path));
        } catch (IOException e) {
            throw new IllegalArgumentException("Failed to read PEM file '" + path + "': " + e.getMessage(), e);
        }
    }

    /**
     * Gets a configuration value from system property, falling back to default.
     */
    static String getSystemProperty(String propertyName, String defaultValue) {
        String value = System.getProperty(propertyName);
        if (value != null && !value.isEmpty()) {
            return value;
        }
        return defaultValue;
    }

    private MetricExporter createExporter(String endpoint, String protocol) {
        if ("http".equalsIgnoreCase(protocol)) {
            var builder = OtlpHttpMetricExporter.builder()
                    .setEndpoint(normalizeHttpEndpoint(endpoint))
                    .setTimeout(Duration.ofSeconds(10));
            effectiveHeaders.forEach(builder::addHeader);
            if (effectiveTrustedCertsPem != null) {
                builder.setTrustedCertificates(effectiveTrustedCertsPem);
            }
            if (effectiveClientKeyPem != null && effectiveClientCertPem != null) {
                builder.setClientTls(effectiveClientKeyPem, effectiveClientCertPem);
            }
            return builder.build();
        } else {
            // Default to gRPC
            var builder = OtlpGrpcMetricExporter.builder()
                    .setEndpoint(endpoint)
                    .setTimeout(Duration.ofSeconds(10));
            effectiveHeaders.forEach(builder::addHeader);
            if (effectiveTrustedCertsPem != null) {
                builder.setTrustedCertificates(effectiveTrustedCertsPem);
            }
            if (effectiveClientKeyPem != null && effectiveClientCertPem != null) {
                builder.setClientTls(effectiveClientKeyPem, effectiveClientCertPem);
            }
            return builder.build();
        }
    }

    /**
     * Normalizes HTTP endpoint by:
     * 1. Adding default port (80 for http, 443 for https) if not specified
     * 2. Appending /v1/metrics if not already present
     * This allows users to specify either the base URL or the full path.
     */
    static String normalizeHttpEndpoint(String endpoint) {
        String normalizedEndpoint = endpoint;

        // Add default port if not specified
        try {
            java.net.URI uri = new java.net.URI(endpoint);
            if (uri.getPort() == -1) {
                int defaultPort = "https".equalsIgnoreCase(uri.getScheme()) ? 443 : 80;
                // Rebuild URI with explicit port
                normalizedEndpoint = new java.net.URI(
                        uri.getScheme(),
                        uri.getUserInfo(),
                        uri.getHost(),
                        defaultPort,
                        uri.getPath(),
                        uri.getQuery(),
                        uri.getFragment()
                ).toString();
            }
        } catch (java.net.URISyntaxException e) {
            LOGGER.warn("Could not parse endpoint URL '{}', using as-is: {}", endpoint, e.getMessage());
        }

        // Append /v1/metrics if not present
        return normalizedEndpoint.endsWith("/v1/metrics") ? normalizedEndpoint : normalizedEndpoint + "/v1/metrics";
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
        gauges.add(gauge);
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
                        } else if (value != null) {
                            LOGGER.debug("Skipping negative counter value for {}: {}", name, value);
                        }
                    } catch (Exception e) {
                        LOGGER.debug("Error collecting observable counter {}: {}", name, e.getMessage());
                    }
                });
        observableCounters.add(counter);
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
