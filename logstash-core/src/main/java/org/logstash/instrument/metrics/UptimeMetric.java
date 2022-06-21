package org.logstash.instrument.metrics;

import java.time.Clock;
import java.util.Objects;

import static org.logstash.instrument.metrics.MetricType.COUNTER_LONG;

/**
 * A {@link Clock}-based {@link Metric}, whose value is the number of milliseconds
 * that have elapsed since the metric was created.
 */
public class UptimeMetric implements Metric<Long> {

    private final Clock clock;
    private final Long start;

    private final String name;

    public UptimeMetric(final String name) {
        this(Clock.systemUTC(), name);
    }

    UptimeMetric(final Clock clock, final String name) {
        this.start = clock.millis();
        this.clock = clock;
        this.name = Objects.requireNonNullElse(name, "uptime_in_millis");
    }

    @Override
    public String getName() {
        return this.name;
    }

    @Override
    public MetricType getType() {
        return COUNTER_LONG;
    }

    @Override
    public Long getValue() {
        return clock.millis() - start;
    }
}
