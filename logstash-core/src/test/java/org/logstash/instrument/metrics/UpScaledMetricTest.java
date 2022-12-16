package org.logstash.instrument.metrics;

import org.junit.Assert;
import org.junit.Before;
import org.junit.Test;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;

public class UpScaledMetricTest {

    Metric<Number> uptimeMetric;

    ManualAdvanceClock clock;

    @Before
    public void setUp() {
        clock = new ManualAdvanceClock(Instant.now());
        uptimeMetric = new UptimeMetric("uptime", clock::nanoTime).withUnitsPrecise(UptimeMetric.ScaleUnits.SECONDS);
    }

    @Test
    public void testGetType() {
        UpScaledMetric upScaledMetric = new UpScaledMetric("up_scaled_metric", uptimeMetric, 2);
        Assert.assertEquals(upScaledMetric.getType(), MetricType.GAUGE_NUMBER);
    }

    @Test
    public void testGetValue() {
        UpScaledMetric upScaledMetric = new UpScaledMetric("up_scaled_metric", uptimeMetric, 10);
        clock.advance(Duration.ofSeconds(10));
        Assert.assertTrue(BigDecimal.valueOf(100.0d).compareTo(upScaledMetric.getValue()) == 0);
    }
}