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

import java.math.BigDecimal;
import java.util.Objects;
import java.util.concurrent.TimeUnit;
import java.util.function.LongSupplier;

/**
 * The {@link UptimeMetric} is an auto-advancing {@link Metric} whose value
 * represents the amount of time since instantiation. It can be made to track the
 * advancement of the clock in one of several {@link TimeUnit}s.
 */
public class UptimeMetric extends AbstractMetric<Long> {
    private final LongSupplier nanoTimeSupplier;
    private final long startNanos;

    public enum ScaleUnits {
        NANOSECONDS(0),
        MICROSECONDS(3),
        MILLISECONDS(6),
        SECONDS(9),
        ;

        private final int nanoRelativeDecimalShift;

        ScaleUnits(final int nanoRelativeDecimalShift) {
            this.nanoRelativeDecimalShift = nanoRelativeDecimalShift;
        }
    }
    private final TimeUnit timeUnit;

    /**
     * Constructs an {@link UptimeMetric} whose name is "uptime_in_millis" and whose units are milliseconds
     */
    public UptimeMetric() {
        this(MetricKeys.UPTIME_IN_MILLIS_KEY.asJavaString());
    }

    /**
     * Constructs an {@link UptimeMetric} with the provided name.
     * @param name the name of the metric, which is used by our metric store, API retrieval, etc.
     */
    public UptimeMetric(final String name) {
        this(name, System::nanoTime);
    }

    UptimeMetric(final String name, final LongSupplier nanoTimeSupplier) {
        this(name, nanoTimeSupplier, nanoTimeSupplier.getAsLong(), TimeUnit.MILLISECONDS);
    }

    private UptimeMetric(final String name, final LongSupplier nanoTimeSupplier, final long startNanos, final TimeUnit timeUnit) {
        super(Objects.requireNonNull(name, "name"));
        this.nanoTimeSupplier = Objects.requireNonNull(nanoTimeSupplier, "nanoTimeSupplier");
        this.timeUnit = Objects.requireNonNull(timeUnit, "timeUnit");
        this.startNanos = Objects.requireNonNull(startNanos, "startNanos");
    }

    /**
     * @return the number of {@link TimeUnit}s that have elapsed
     *         since this {@link UptimeMetric} was instantiated
     */
    @Override
    public Long getValue() {
        return this.timeUnit.convert(getElapsedNanos(), TimeUnit.NANOSECONDS);
    }

    long getElapsedNanos() {
        return this.nanoTimeSupplier.getAsLong() - this.startNanos;
    }

    /**
     * @return the {@link MetricType}{@code .COUNTER_LONG} associated with
     *         long-valued metrics that only-increment, for use in Monitoring data structuring.
     */
    @Override
    public MetricType getType() {
        return MetricType.COUNTER_LONG;
    }

    /**
     * @return the {@link TimeUnit} associated with this {@link UptimeMetric}.
     */
    public TimeUnit getTimeUnit() {
        return timeUnit;
    }

    /**
     * Constructs a _copy_ of this {@link UptimeMetric} with a new name and timeUnit, but whose
     * uptime is tracking from the same instant as this instance.
     *
     * @param name the new metric's name (typically includes units)
     * @param timeUnit the new metric's units
     * @return a _copy_ of this {@link UptimeMetric}.
     */
    public UptimeMetric withTimeUnit(final String name, final TimeUnit timeUnit) {
        return new UptimeMetric(name, this.nanoTimeSupplier, this.startNanos, timeUnit);
    }

    /**
     * Constructs a _view_ into this {@link UptimeMetric} whose value is a decimal number
     * containing subunit precision.
     *
     * @param name the name of the metric
     * @param scaleUnits the desired scale
     * @return a {@link BigDecimal} representing the whole-and-fractional number
     *         of {@link ScaleUnits} that have elapsed.
     */
    public ScaledView withUnitsPrecise(final String name, final ScaleUnits scaleUnits) {
        return new ScaledView(name, this::getElapsedNanos, scaleUnits.nanoRelativeDecimalShift);
    }

    /**
     * {@code name} defaults to something vaguely descriptive.
     * Useful when the caller doesn't need the metric name.
     *
     * @see UptimeMetric#withUnitsPrecise(String, ScaleUnits)
     */
    public ScaledView withUnitsPrecise(final ScaleUnits scaleUnits) {
        final String name = String.format("%s_scaled_to_%s", getName(), scaleUnits.name());
        return this.withUnitsPrecise(name, scaleUnits);
    }

    static class ScaledView implements Metric<Number> {
        private final String name;
        private final int nanoRelativeDecimalShift;
        private final LongSupplier elapsedNanosSupplier;

        ScaledView(final String name,
                   final LongSupplier elapsedNanosSupplier,
                   final int nanoRelativeDecimalShift) {
            this.name = name;
            this.nanoRelativeDecimalShift = nanoRelativeDecimalShift;
            this.elapsedNanosSupplier = elapsedNanosSupplier;
        }

        @Override
        public String getName() {
            return this.name;
        }

        @Override
        public MetricType getType() {
            return MetricType.COUNTER_DECIMAL;
        }

        @Override
        public BigDecimal getValue() {
            return BigDecimal.valueOf(elapsedNanosSupplier.getAsLong(), nanoRelativeDecimalShift);
        }
    }
}
