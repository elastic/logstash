package org.logstash.instrument.metrics;

import org.junit.Test;
import org.logstash.instrument.metrics.counter.LongCounter;

import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Map;

import static org.hamcrest.Matchers.anEmptyMap;
import static org.hamcrest.Matchers.hasEntry;
import static org.hamcrest.Matchers.is;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertThat;
import static org.junit.Assert.assertTrue;
import static org.logstash.instrument.metrics.SimpleFlowMetric.LIFETIME_KEY;
import static org.logstash.instrument.metrics.SimpleFlowMetric.CURRENT_KEY;

public class SimpleFlowMetricTest {
    @Test
    public void testBaselineFunctionality() {
        final ManualAdvanceClock clock = new ManualAdvanceClock(Instant.now());
        final LongCounter numeratorMetric = new LongCounter(MetricKeys.EVENTS_KEY.asJavaString());
        final Metric<Number> denominatorMetric = new UptimeMetric("uptime", clock::nanoTime).withUnitsPrecise(UptimeMetric.ScaleUnits.SECONDS);
        final FlowMetric instance = new SimpleFlowMetric(clock::nanoTime, "flow", numeratorMetric, denominatorMetric);

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

        // less than half a second passes, during which 0 events are seen by our numerator.
        // when our two most recent captures are very close together, we want to make sure that
        // we continue to provide _meaningful_ metrics, namely that:
        // (a) our CURRENT_KEY and LIFETIME_KEY account for newest capture, and
        // (b) our CURRENT_KEY does not report _only_ the delta since the very-recent capture
        clock.advance(Duration.ofMillis(10));
        instance.capture();
        final Map<String, Double> ratesAfterSmallAdvanceCapture = instance.getValue();
        assertFalse(ratesAfterNthCapture.isEmpty());
        assertEquals(Map.of(LIFETIME_KEY, 367.4, CURRENT_KEY, 377.6), ratesAfterSmallAdvanceCapture);
    }

    @Test
    public void testFunctionalityWhenMetricInitiallyReturnsNullValue() {
        final ManualAdvanceClock clock = new ManualAdvanceClock(Instant.now());
        final NullableLongMetric numeratorMetric = new NullableLongMetric(MetricKeys.EVENTS_KEY.asJavaString());
        final Metric<Number> denominatorMetric = new UptimeMetric("uptime", clock::nanoTime).withUnitsPrecise(UptimeMetric.ScaleUnits.SECONDS);

        final SimpleFlowMetric flowMetric = new SimpleFlowMetric(clock::nanoTime, "flow", numeratorMetric, denominatorMetric);

        // for 1000 seconds, our captures hit a metric that is returning null.
        for(int i=1; i < 1000; i++) {
            clock.advance(Duration.ofSeconds(1));
            flowMetric.capture();
        }

        // our metric has only returned null so far, so we don't expect any captures.
        assertThat(flowMetric.getValue(), is(anEmptyMap()));

        // increment our metric by a lot, ensuring that the first non-null value available
        // is big enough to be detected if it is included in our rates
        numeratorMetric.increment(10_000_000L);

        // now we begin incrementing out metric, which makes it stop returning null.
        for(int i=1; i<3_000; i++) {
            clock.advance(Duration.ofSeconds(1));
            numeratorMetric.increment(i);
            flowMetric.capture();
        }

        // ensure that our metrics cover the _available_ data and no more.
        final Map<String, Double> flowMetricValue = flowMetric.getValue();
        assertThat(flowMetricValue, hasEntry("current",         2999.0));
        assertThat(flowMetricValue, hasEntry("lifetime",        1501.0));
    }
}
