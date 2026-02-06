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

package org.logstash.instrument.metrics;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.logstash.util.SetOnceReference;

import java.time.Duration;
import java.util.Collection;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.OptionalDouble;
import java.util.function.LongSupplier;
import java.util.function.ToLongBiFunction;
import java.util.stream.Collectors;

/**
 * The {@link ExtendedFlowMetric} is an implementation of {@link FlowMetric} that produces
 * a variable number of rates defined by {@link FlowMetricRetentionPolicy}-s, retaining no
 * more {@link FlowCapture}s than necessary to satisfy the requested resolution or the
 * requested retention. This implementation is lock-free and concurrency-safe.
 */
public class ExtendedFlowMetric extends BaseFlowMetric {
    static final Logger LOGGER = LogManager.getLogger(ExtendedFlowMetric.class);

    private final Collection<? extends FlowMetricRetentionPolicy> retentionPolicies;

    // set-once atomic reference; see ExtendedFlowMetric#appendCapture(FlowCapture)
    private final SetOnceReference<List<RetentionWindow<FlowCapture, Double>>> retentionWindows = SetOnceReference.unset();

    public ExtendedFlowMetric(final String name,
                              final Metric<? extends Number> numeratorMetric,
                              final Metric<? extends Number> denominatorMetric) {
        this(System::nanoTime, name, numeratorMetric, denominatorMetric);
    }

    ExtendedFlowMetric(final LongSupplier nanoTimeSupplier,
                       final String name,
                       final Metric<? extends Number> numeratorMetric,
                       final Metric<? extends Number> denominatorMetric,
                       final Collection<? extends FlowMetricRetentionPolicy> retentionPolicies) {
        super(nanoTimeSupplier, name, numeratorMetric, denominatorMetric);
        this.retentionPolicies = List.copyOf(retentionPolicies);

        this.lifetimeBaseline.asOptional().ifPresent(this::appendCapture);
    }

    public ExtendedFlowMetric(final LongSupplier nanoTimeSupplier,
                              final String name,
                              final Metric<? extends Number> numeratorMetric,
                              final Metric<? extends Number> denominatorMetric) {
        this(nanoTimeSupplier, name, numeratorMetric, denominatorMetric, BuiltInFlowMetricRetentionPolicies.all());
    }

    @Override
    public void capture() {
        doCapture().ifPresent(this::appendCapture);
    }

    @Override
    public Map<String, Double> getValue() {
        capture();

        if (!lifetimeBaseline.isSet()) { return Map.of(); }
        if (!retentionWindows.isSet()) { return Map.of(); }

        final Map<String, Double> rates = new LinkedHashMap<>();
        for (RetentionWindow<FlowCapture, Double> window : this.retentionWindows.get()) {
            window.calculateValue().ifPresent(value -> rates.put(window.policy.policyName(), value));
        }

        return Collections.unmodifiableMap(rates);
    }

    /**
     * Appends the given {@link FlowCapture} to the existing {@link RetentionWindow}s, XOR creates
     * a new list of {@link RetentionWindow} using the provided {@link FlowCapture} as a baseline.
     * This is concurrency-safe and uses non-volatile memory access in the hot path.
     */
    private void appendCapture(final FlowCapture capture) {
        this.retentionWindows.ifSetOrElseSupply(
                (existing) -> injectIntoRetentionWindows(existing, capture),
                (        ) -> initRetentionWindows(retentionPolicies, capture)
        );
    }

    private static List<RetentionWindow<FlowCapture,Double>> initRetentionWindows(final Collection<? extends FlowMetricRetentionPolicy> retentionPolicies,
                                                              final FlowCapture capture) {
        return retentionPolicies.stream()
                                .map((p) -> new FlowRetentionWindow(p, capture))
                                .collect(Collectors.toUnmodifiableList());
    }

    private static void injectIntoRetentionWindows(final List<RetentionWindow<FlowCapture, Double>> retentionWindows, final FlowCapture capture) {
        retentionWindows.forEach((rw) -> rw.append(capture));
    }

    /**
     * Internal introspection for tests to measure how many captures we are retaining.
     * @return the number of captures in all tracked windows
     */
    int estimateCapturesRetained() {
        return this.retentionWindows.orElse(Collections.emptyList())
                                    .stream()
                                    .map(RetentionWindow::estimateSize)
                                    .mapToInt(Integer::intValue)
                                    .sum();
    }

    /**
     * Internal introspection for tests to measure excess retention.
     * @param retentionWindowFunction given a policy, return a retention window, in nanos
     * @return the sum of over-retention durations.
     */
    Duration estimateExcessRetained(final ToLongBiFunction<FlowMetricRetentionPolicy, Long> retentionWindowFunction) {
        final long currentNanoTime = nanoTimeSupplier.getAsLong();
        final long cumulativeExcessRetained =
                this.retentionWindows.orElse(Collections.emptyList())
                        .stream()
                        .map(s -> s.excessRetained(retentionWindowFunction.applyAsLong(s.policy, currentNanoTime)))
                        .mapToLong(Long::longValue)
                        .sum();
        return Duration.ofNanos(cumulativeExcessRetained);
    }

    static class FlowRetentionWindow extends RetentionWindow<FlowCapture, Double> {

        FlowRetentionWindow(FlowMetricRetentionPolicy policy, FlowCapture zeroCapture) {
            super(policy, zeroCapture);
        }

        @Override
        FlowCapture mergeCaptures(FlowCapture oldCapture, FlowCapture newCapture) {
            if (oldCapture == null) {
                return newCapture;
            }
            if (newCapture == null) {
                return oldCapture;
            }

            return (oldCapture.nanoTime() > newCapture.nanoTime()) ? oldCapture : newCapture;
        }

        @Override
        Optional<Double> calculateValue() {
            return calculateFromBaseline((compareCapture, baselineCapture) -> {
                if (compareCapture == null) { return Optional.empty(); }
                if (baselineCapture == null) { return Optional.empty(); }

                final OptionalDouble rate = calculateRate(compareCapture, baselineCapture);

                // convert from OptionalDouble to Optional<Double>
                return rate.isPresent() ? Optional.of(rate.getAsDouble()) : Optional.empty();
            });
        }
    }
}
