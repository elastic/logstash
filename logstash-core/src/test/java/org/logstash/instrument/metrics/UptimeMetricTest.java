package org.logstash.instrument.metrics;

import org.junit.Test;

import java.time.Duration;
import java.time.Instant;
import java.util.concurrent.TimeUnit;

import static org.junit.Assert.assertEquals;

public class UptimeMetricTest {

    @Test
    public void testDefaultConstructor() {
        final UptimeMetric defaultConstructorUptimeMetric = new UptimeMetric();
        assertEquals(MetricKeys.UPTIME_IN_MILLIS_KEY, defaultConstructorUptimeMetric.getName());
        assertEquals(TimeUnit.MILLISECONDS, defaultConstructorUptimeMetric.getTimeUnit());
    }

    @Test
    public void getNameExplicit() {
        final String customName = "custom_uptime_name";
        assertEquals(customName, new UptimeMetric(customName, TimeUnit.MILLISECONDS).getName());
    }

    @Test
    public void getType() {
        assertEquals(MetricType.COUNTER_LONG, new UptimeMetric().getType());
    }

    @Test
    public void getValue() {
        final ManualAdvanceClock clock = new ManualAdvanceClock(Instant.now());
        final UptimeMetric uptimeMetric = new UptimeMetric("up", TimeUnit.MILLISECONDS, clock::nanoTime);
        assertEquals(Long.valueOf(0L), uptimeMetric.getValue());

        clock.advance(Duration.ofMillis(123));
        assertEquals(Long.valueOf(123L), uptimeMetric.getValue());

        clock.advance(Duration.ofMillis(456));
        assertEquals(Long.valueOf(579L), uptimeMetric.getValue());

        clock.advance(Duration.ofMinutes(15));
        assertEquals(Long.valueOf(900579L), uptimeMetric.getValue());

        clock.advance(Duration.ofHours(712));
        assertEquals(Long.valueOf(2564100579L), uptimeMetric.getValue());
    }

    @Test
    public void withTemporalUnit() {
        final ManualAdvanceClock clock = new ManualAdvanceClock(Instant.now());
        final UptimeMetric uptimeMetric = new UptimeMetric("up_millis", TimeUnit.MILLISECONDS, clock::nanoTime);
        clock.advance(Duration.ofMillis(1_000_000_000));

        // set-up: ensure advancing nanos reflects in our milli-based uptime
        assertEquals(Long.valueOf(1_000_000_000), uptimeMetric.getValue());

        final UptimeMetric secondsBasedCopy = uptimeMetric.withTimeUnit("up_seconds", TimeUnit.SECONDS);
        assertEquals(Long.valueOf(1_000_000), secondsBasedCopy.getValue());
    }

}