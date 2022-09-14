package org.logstash.instrument.metrics;

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

    private final TimeUnit timeUnit;

    /**
     * Constructs an {@link UptimeMetric} whose name is "uptime_in_millis" and whose units are milliseconds
     */
    public UptimeMetric() {
        this(MetricKeys.UPTIME_IN_MILLIS_KEY.asJavaString());
    }

    public UptimeMetric(final String name) {
        this(name, TimeUnit.MILLISECONDS);
    }

    /**
     * Constructs an {@link UptimeMetric} with the provided name and units.
     * @param name the name of the metric, which is used by our metric store, API retrieval, etc.
     * @param timeUnit the units in which to keep track of uptime (millis, seconds, etc.)
     */
    public UptimeMetric(final String name, final TimeUnit timeUnit) {
        this(name, timeUnit, System::nanoTime);
    }

    UptimeMetric(final String name, final TimeUnit timeUnit, final LongSupplier nanoTimeSupplier) {
        this(name, timeUnit, nanoTimeSupplier, nanoTimeSupplier.getAsLong());
    }

    UptimeMetric(final String name, final TimeUnit timeUnit, final LongSupplier nanoTimeSupplier, final long startNanos) {
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
        final long elapsedNanos = this.nanoTimeSupplier.getAsLong() - this.startNanos;

        return this.timeUnit.convert(elapsedNanos, TimeUnit.NANOSECONDS);
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
        return new UptimeMetric(name, timeUnit, this.nanoTimeSupplier, this.startNanos);
    }
}
