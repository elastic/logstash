package org.logstash.instrument.metrics;

import java.time.Clock;

import static org.logstash.instrument.metrics.MetricType.COUNTER_LONG;

public class UptimeMetric implements Metric<Long> {

    private final Clock clock;
    private final Long start;

    public UptimeMetric(final Clock clock) {
        this.clock = clock;
        this.start = clock.millis();
    }

    public UptimeMetric() {
        this(Clock.systemUTC());
    }

    @Override
    public String getName() {
        return "uptime";
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
