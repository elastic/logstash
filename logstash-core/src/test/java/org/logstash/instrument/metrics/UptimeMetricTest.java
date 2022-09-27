package org.logstash.instrument.metrics;

import org.junit.Test;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.util.concurrent.TimeUnit;

import static org.junit.Assert.assertEquals;

public class UptimeMetricTest {

    @Test
    public void testDefaultConstructor() {
        final UptimeMetric defaultConstructorUptimeMetric = new UptimeMetric();
        assertEquals(MetricKeys.UPTIME_IN_MILLIS_KEY.asJavaString(), defaultConstructorUptimeMetric.getName());
        assertEquals(TimeUnit.MILLISECONDS, defaultConstructorUptimeMetric.getTimeUnit());
    }

    @Test
    public void getNameExplicit() {
        final String customName = "custom_uptime_name";
        assertEquals(customName, new UptimeMetric(customName).getName());
    }

    @Test
    public void getType() {
        assertEquals(MetricType.COUNTER_LONG, new UptimeMetric().getType());
    }

    @Test
    public void getValue() {
        final ManualAdvanceClock clock = new ManualAdvanceClock(Instant.now());
        final UptimeMetric uptimeMetric = new UptimeMetric("up", clock::nanoTime);
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
        final UptimeMetric uptimeMetric = new UptimeMetric("up_millis", clock::nanoTime);
        clock.advance(Duration.ofMillis(1_000_000_000));

        // set-up: ensure advancing nanos reflects in our milli-based uptime
        assertEquals(Long.valueOf(1_000_000_000), uptimeMetric.getValue());

        final UptimeMetric secondsBasedCopy = uptimeMetric.withTimeUnit("up_seconds", TimeUnit.SECONDS);
        assertEquals(Long.valueOf(1_000_000), secondsBasedCopy.getValue());

        clock.advance(Duration.ofMillis(1_999));
        assertEquals(Long.valueOf(1_000_001_999), uptimeMetric.getValue());
        assertEquals(Long.valueOf(1_000_001), secondsBasedCopy.getValue());
    }

    @Test
    public void withUnitsPrecise() {
        final ManualAdvanceClock clock = new ManualAdvanceClock(Instant.now());
        final UptimeMetric uptimeMetric = new UptimeMetric("up_millis", clock::nanoTime);
        clock.advance(Duration.ofNanos(123_456_789_987L)); // 123.xx seconds

        // set-up: ensure advancing nanos reflects in our milli-based uptime
        assertEquals(Long.valueOf(123_456L), uptimeMetric.getValue());

        final UptimeMetric.ScaledView secondsBasedView = uptimeMetric.withUnitsPrecise("up_seconds", UptimeMetric.ScaleUnits.SECONDS);
        final UptimeMetric.ScaledView millisecondsBasedView = uptimeMetric.withUnitsPrecise("up_millis", UptimeMetric.ScaleUnits.MILLISECONDS);
        final UptimeMetric.ScaledView microsecondsBasedView = uptimeMetric.withUnitsPrecise("up_micros", UptimeMetric.ScaleUnits.MICROSECONDS);
        final UptimeMetric.ScaledView nanosecondsBasedView = uptimeMetric.withUnitsPrecise("up_nanos", UptimeMetric.ScaleUnits.NANOSECONDS);

        assertEquals(new BigDecimal("123.456789987"), secondsBasedView.getValue());
        assertEquals(new BigDecimal("123456.789987"), millisecondsBasedView.getValue());
        assertEquals(new BigDecimal("123456789.987"), microsecondsBasedView.getValue());
        assertEquals(new BigDecimal("123456789987"), nanosecondsBasedView.getValue());

        clock.advance(Duration.ofMillis(1_999));
        assertEquals(Long.valueOf(125_455L), uptimeMetric.getValue());
        assertEquals(new BigDecimal("125.455789987"), secondsBasedView.getValue());
        assertEquals(new BigDecimal("125455.789987"), millisecondsBasedView.getValue());
        assertEquals(new BigDecimal("125455789.987"), microsecondsBasedView.getValue());
        assertEquals(new BigDecimal("125455789987"), nanosecondsBasedView.getValue());
    }

}