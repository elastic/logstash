package org.logstash.instrument.metrics;

import org.junit.Test;
import org.logstash.instrument.metrics.counter.LongCounter;

import java.time.Duration;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Map;
import java.util.concurrent.TimeUnit;

import static org.junit.Assert.*;
import static org.logstash.instrument.metrics.FlowMetric.CURRENT_KEY;
import static org.logstash.instrument.metrics.FlowMetric.LIFETIME_KEY;

public class FlowMetricTest {
    @Test
    public void testBaselineFunctionality() {
        final ManualAdvanceClock clock = new ManualAdvanceClock(Instant.now());
        final LongCounter numeratorMetric = new LongCounter("events");
        final Metric<Long> denominatorMetric = new UptimeMetric("uptime", TimeUnit.SECONDS, clock::nanoTime);
        final FlowMetric instance = new FlowMetric("flow", numeratorMetric, denominatorMetric);

        final Map<String, Double> ratesBeforeCaptures = instance.getValue();
        assertTrue(ratesBeforeCaptures.isEmpty());

        // 5 seconds pass, during which 1000 events are processed
        clock.advance(Duration.ofSeconds(5));
        numeratorMetric.increment(1000);
        instance.capture();
        final Map<String, Double> ratesAfterFirstCapture = instance.getValue();
        assertFalse(ratesAfterFirstCapture.isEmpty());
        assertEquals(Map.of(LIFETIME_KEY, 200.0, CURRENT_KEY, 200.0), ratesAfterFirstCapture);

        // 5 more seconds pass, during which 2000 more events are processed
        clock.advance(Duration.ofSeconds(5));
        numeratorMetric.increment(2000);
        instance.capture();
        final Map<String, Double> ratesAfterSecondCapture = instance.getValue();
        assertFalse(ratesAfterSecondCapture.isEmpty());
        assertEquals(Map.of(LIFETIME_KEY, 300.0, CURRENT_KEY, 400.0), ratesAfterSecondCapture);

        // 30 seconds pass, during which 11700 more events are seen by our numerator
        for (Integer eventCount : List.of(1883, 2117, 1901, 2299, 1608, 1892)) {
            clock.advance(Duration.ofSeconds(5));
            numeratorMetric.increment(eventCount);
            instance.capture();
        }
        final Map<String, Double> ratesAfterNthCapture = instance.getValue();
        assertFalse(ratesAfterNthCapture.isEmpty());
        assertEquals(Map.of(LIFETIME_KEY, 367.5, CURRENT_KEY, 378.4), ratesAfterNthCapture);
    }
}
