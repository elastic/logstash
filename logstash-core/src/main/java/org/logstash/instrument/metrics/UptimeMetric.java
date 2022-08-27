package org.logstash.instrument.metrics;

import java.time.Clock;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.time.temporal.TemporalUnit;
import java.util.Objects;

/**
 * The {@link UptimeMetric} is an auto-advancing {@link Metric} whose value
 * represents the amount of time since instantiation. It can be made to track the
 * advancement of the clock in one of several {@link TemporalUnit}s.
 */
public class UptimeMetric extends AbstractMetric<Long> {
    private final Clock clock;
    private final Instant startInstant;

    private final TemporalUnit temporalUnit;

    /**
     * Constructs an {@link UptimeMetric} whose name is "uptime_in_millis" and whose units are milliseconds
     */
    public UptimeMetric() {
        this("uptime_in_millis", ChronoUnit.MILLIS);
    }

    /**
     * Constructs an {@link UptimeMetric} with the provided name and units.
     * @param name the name of the metric, which is used by our metric store, API retrieval, etc.
     * @param temporalUnit the units in which to keep track of uptime (millis, seconds, etc.)
     */
    public UptimeMetric(final String name, final TemporalUnit temporalUnit) {
        this(name, temporalUnit, Clock.systemUTC());
    }

    UptimeMetric(final String name, final TemporalUnit temporalUnit, final Clock clock) {
        this(name, temporalUnit, clock, clock.instant());
    }

    UptimeMetric(final String name, final TemporalUnit temporalUnit, final Clock clock, final Instant startInstant) {
        super(Objects.requireNonNull(name, "name"));
        this.clock = Objects.requireNonNull(clock, "clock");
        this.temporalUnit = Objects.requireNonNull(temporalUnit, "temporalUnit");
        this.startInstant = Objects.requireNonNull(startInstant, "startInstant");
    }

    /**
     * @return the number of {@link TemporalUnit}s that have elapsed
     *         since this {@link UptimeMetric} was instantiated
     */
    @Override
    public Long getValue() {
        return this.startInstant.until(this.clock.instant(), temporalUnit);
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
     * @return the {@link TemporalUnit} associated with this {@link UptimeMetric}.
     */
    public TemporalUnit getTemporalUnit() {
        return temporalUnit;
    }

    /**
     * Constructs a _copy_ of this {@link UptimeMetric} with a new name and temporalUnit, but whose
     * uptime is tracking from the same instant as this instance.
     *
     * @param name the new metric's name (typically includes units)
     * @param temporalUnit the new metric's units
     * @return a _copy_ of this {@link UptimeMetric}.
     */
    public UptimeMetric withTemporalUnit(final String name, final TemporalUnit temporalUnit) {
        return new UptimeMetric(name, temporalUnit, this.clock, this.startInstant);
    }
}