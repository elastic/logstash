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
 * Usage from Ruby:
 *   java_import 'org.logstash.instrument.metrics.otel.OtelMetricsService'
 *   service = OtelMetricsService.new(endpoint, node_id, node_name, interval_secs, "grpc", nil)
 *   service.registerGauge("metric.name", "description", "unit", -> { get_value() }, Attributes.empty)
 */
public class OtelMetricsService {

    private static final Logger LOGGER = LogManager.getLogger(OtelMetricsService.class);

    private final SdkMeterProvider meterProvider;
    private final Meter meter;
    // Keep references to prevent garbage collection of observable instruments
    private final Map<String, ObservableLongGauge> gauges = new ConcurrentHashMap<>();
    private final Map<String, ObservableLongCounter> observableCounters = new ConcurrentHashMap<>();

    private final String authorizationHeader;

    /**
     * Creates a new Otel metrics service.
     *
     * @param endpoint             OTLP endpoint (e.g., "http://localhost:4317")
     * @param nodeId               Logstash node ID
     * @param nodeName             Logstash node name
     * @param intervalSeconds      Export interval in seconds
     * @param protocol             "grpc" or "http"
     * @param resourceAttributes   Additional resource attributes (comma-separated key=value pairs)
     * @param authorizationHeader  Authorization header value (e.g., "ApiKey xxx" or "Bearer xxx"), or null
     */
    public OtelMetricsService(String endpoint, String nodeId, String nodeName,
                              int intervalSeconds, String protocol, String resourceAttributes,
                              String authorizationHeader) {
        LOGGER.info("Initializing OpenTelemetry metrics export to {} (protocol: {}, interval: {}s)",
                endpoint, protocol, intervalSeconds);
        this.authorizationHeader = authorizationHeader;

        // Build resource attributes
        AttributesBuilder resourceAttrsBuilder = Attributes.builder()
                .put(AttributeKey.stringKey("service.name"), "logstash")
                .put(AttributeKey.stringKey("service.instance.id"), nodeId)
                .put(AttributeKey.stringKey("host.name"), nodeName);

        // Parse additional resource attributes if provided
        if (resourceAttributes != null && !resourceAttributes.isEmpty()) {
            parseResourceAttributes(resourceAttributes, resourceAttrsBuilder);
        }

        Resource resource = Resource.getDefault().merge(
                Resource.create(resourceAttrsBuilder.build())
        );

        // Create the appropriate exporter based on protocol
        MetricExporter exporter = createExporter(endpoint, protocol);

        // Create periodic reader
        PeriodicMetricReader metricReader = PeriodicMetricReader.builder(exporter)
                .setInterval(Duration.ofSeconds(intervalSeconds))
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

    private MetricExporter createExporter(String endpoint, String protocol) {
        if ("http".equalsIgnoreCase(protocol)) {
            var builder = OtlpHttpMetricExporter.builder()
                    .setEndpoint(endpoint + "/v1/metrics")
                    .setTimeout(Duration.ofSeconds(10));
            if (authorizationHeader != null && !authorizationHeader.isEmpty()) {
                builder.addHeader("Authorization", authorizationHeader);
            }
            return builder.build();
        } else {
            // Default to gRPC
            var builder = OtlpGrpcMetricExporter.builder()
                    .setEndpoint(endpoint)
                    .setTimeout(Duration.ofSeconds(10));
            if (authorizationHeader != null && !authorizationHeader.isEmpty()) {
                builder.addHeader("Authorization", authorizationHeader);
            }
            return builder.build();
        }
    }

    private void parseResourceAttributes(String attributes, AttributesBuilder builder) {
        for (String pair : attributes.split(",")) {
            String[] keyValue = pair.trim().split("=", 2);
            if (keyValue.length == 2) {
                builder.put(AttributeKey.stringKey(keyValue[0].trim()), keyValue[1].trim());
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
            meterProvider.close();
        }
        LOGGER.info("OpenTelemetry metrics service shut down");
    }
}
