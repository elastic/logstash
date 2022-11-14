package org.logstash.instrument.metrics;

import org.junit.Assert;
import org.junit.Test;
import org.logstash.instrument.metrics.counter.LongCounter;

import java.time.Duration;
import java.time.Instant;
import java.util.Map;

import static org.logstash.instrument.metrics.BaseFlowMetric.LIFETIME_KEY;
import static org.logstash.instrument.metrics.SimpleFlowMetric.CURRENT_KEY;

public class SimpleFracturedFlowMetricTest {

    @Test
    public void testGetValue() {
        final Number workers = 3;
        final ManualAdvanceClock clock = new ManualAdvanceClock(Instant.now());
        final LongCounter numeratorMetric = new LongCounter(MetricKeys.EVENTS_KEY.asJavaString());
        final Metric<Number> denominatorMetric = new UptimeMetric("uptime", clock::nanoTime).withUnitsPrecise(UptimeMetric.ScaleUnits.SECONDS);
        final FlowMetric instance = new SimpleFracturedFlowMetric(clock::nanoTime, "flow", numeratorMetric, denominatorMetric, workers);

        final Map<String, Double> ratesBeforeCaptures = instance.getValue();
        Assert.assertTrue(ratesBeforeCaptures.isEmpty());

        // 5 seconds pass, during which 1000 events are processed
        clock.advance(Duration.ofSeconds(5));
        numeratorMetric.increment(1000);
        instance.capture();
        final Map<String, Double> ratesAfterFirstCapture = instance.getValue();
        Assert.assertFalse(ratesAfterFirstCapture.isEmpty());
        // takes 6% of worker utilization
        Assert.assertEquals(Map.of(LIFETIME_KEY, 6.0, CURRENT_KEY, 6.0), ratesAfterFirstCapture);

        // 5 more seconds pass, during which 5000 more events are processed
        // rate increased, worker utilization increased
        clock.advance(Duration.ofSeconds(5));
        numeratorMetric.increment(5000);
        instance.capture();
        final Map<String, Double> ratesAfterSecondCapture = instance.getValue();
        Assert.assertFalse(ratesAfterSecondCapture.isEmpty());
        Assert.assertEquals(Map.of(LIFETIME_KEY, 18.0, CURRENT_KEY, 30.0), ratesAfterSecondCapture);
    }
}