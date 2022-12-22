package org.logstash.instrument.metrics;

import org.junit.Test;
import org.logstash.instrument.metrics.counter.LongCounter;
import org.logstash.instrument.metrics.gauge.AbstractGaugeMetric;
import org.logstash.instrument.metrics.gauge.NumberGauge;

import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.function.Consumer;

import static org.hamcrest.Matchers.anEmptyMap;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.hasEntry;
import static org.hamcrest.Matchers.hasKey;
import static org.hamcrest.Matchers.is;
import static org.hamcrest.Matchers.lessThan;
import static org.hamcrest.Matchers.not;
import static org.junit.Assert.assertThat;

public class ExtendedFlowMetricTest {
    @Test
    public void testBaselineFunctionality() {
        final ManualAdvanceClock clock = new ManualAdvanceClock(Instant.now());
        final LongCounter numeratorMetric = new LongCounter(MetricKeys.EVENTS_KEY.asJavaString());
        final Metric<Number> denominatorMetric = new UptimeMetric("uptime", clock::nanoTime).withUnitsPrecise(UptimeMetric.ScaleUnits.SECONDS);

        final ExtendedFlowMetric flowMetric = new ExtendedFlowMetric(clock::nanoTime, "flow", numeratorMetric, denominatorMetric);

        // more than one day of 1s-granularity captures
        // with increasing increments of our numerator metric.
        for(int i=1; i<100_000; i++) {
            clock.advance(Duration.ofSeconds(1));
            numeratorMetric.increment(i);
            flowMetric.capture();

            // since we enforce compaction only on reads, ensure it doesn't grow unbounded with only writes
            // or hold onto captures from before our force compaction threshold
            assertThat(flowMetric.estimateCapturesRetained(), is(lessThan(320)));
            assertThat(flowMetric.estimateExcessRetained(FlowMetricRetentionPolicy::forceCompactionNanos), is(equalTo(Duration.ZERO)));
        }

        // calculate the supplied rates
        final Map<String, Double> flowMetricValue = flowMetric.getValue();
        assertThat(flowMetricValue, hasEntry("current",         99990.0));
        assertThat(flowMetricValue, hasEntry("last_1_minute",   99970.0));
        assertThat(flowMetricValue, hasEntry("last_5_minutes",  99850.0));
        assertThat(flowMetricValue, hasEntry("last_15_minutes", 99550.0));
        assertThat(flowMetricValue, hasEntry("last_1_hour",     98180.0));
        assertThat(flowMetricValue, hasEntry("last_24_hours",   56750.0));
        assertThat(flowMetricValue, hasEntry("lifetime",        50000.0));

        // ensure we are fully-compact.
        assertThat(flowMetric.estimateCapturesRetained(), is(lessThan(250)));
        assertThat(flowMetric.estimateExcessRetained(this::maxRetentionPlusMinResolutionBuffer), is(equalTo(Duration.ZERO)));
    }

    @Test
    public void testFunctionalityWhenMetricInitiallyReturnsNullValue() {
        final ManualAdvanceClock clock = new ManualAdvanceClock(Instant.now());
        final NullableLongMetric numeratorMetric = new NullableLongMetric(MetricKeys.EVENTS_KEY.asJavaString());
        final Metric<Number> denominatorMetric = new UptimeMetric("uptime", clock::nanoTime).withUnitsPrecise(UptimeMetric.ScaleUnits.SECONDS);

        final ExtendedFlowMetric flowMetric = new ExtendedFlowMetric(clock::nanoTime, "flow", numeratorMetric, denominatorMetric);

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
        assertThat(flowMetricValue, hasEntry("current",         2994.0));
        assertThat(flowMetricValue, hasEntry("last_1_minute",   2969.0));
        assertThat(flowMetricValue, hasEntry("last_5_minutes",  2843.0));
        assertThat(flowMetricValue, hasEntry("last_15_minutes", 2536.0));
        assertThat(flowMetricValue, not(hasKey("last_1_hour")));   // window not met
        assertThat(flowMetricValue, not(hasKey("last_24_hours"))); // window not met
        assertThat(flowMetricValue, hasEntry("lifetime",        1501.0));
    }
    @Test
    public void testFunctionalityWithinSecondsOfInitialization() {
        final ManualAdvanceClock clock = new ManualAdvanceClock(Instant.now());
        final LongCounter numeratorMetric = new LongCounter(MetricKeys.EVENTS_KEY.asJavaString());
        final Metric<Number> denominatorMetric = new UptimeMetric("uptime", clock::nanoTime).withUnitsPrecise(UptimeMetric.ScaleUnits.SECONDS);

        final ExtendedFlowMetric flowMetric = new ExtendedFlowMetric(clock::nanoTime, "flow", numeratorMetric, denominatorMetric);

        assertThat(flowMetric.getValue(), is(anEmptyMap()));

        clock.advance(Duration.ofSeconds(1));
        numeratorMetric.increment(17);

        // clock has advanced 1s, but we have performed no explicit captures.
        final Map<String, Double> flowMetricValue = flowMetric.getValue();
        assertThat(flowMetricValue, is(not(anEmptyMap())));
        assertThat(flowMetricValue, hasEntry("current",         17.0));
        assertThat(flowMetricValue, hasEntry("lifetime",        17.0));
    }

    // NOTE: in this test neither numerator nor denominator is tied to our clock,
    // so our clock is ONLY used for retention and NOT factored in to the math for
    // the rate of change of our numerator relative to our denominator.
    // This is useful for clock-invert rates like time-per-event or for ratio
    // rates like events-out-per-events-in where the denominator is not guaranteed
    // to be constantly incrementing.
    @Test
    public void testNonMovingDenominator() {
        final ManualAdvanceClock clock = new ManualAdvanceClock(Instant.now());
        final NumberGauge numeratorMetric = new NumberGauge("numerator", 0);
        final NumberGauge denominatorMetric = new NumberGauge("denominator", 0);

        final ExtendedFlowMetric flowMetric = new ExtendedFlowMetric(clock::nanoTime, "flow", numeratorMetric, denominatorMetric);

        assertThat(flowMetric.getValue(), is(anEmptyMap()));

        clock.advance(Duration.ofSeconds(1));
        numeratorMetric.set(17);
        flowMetric.capture();

        // our numerator has advanced, but our denominator has not.
        // now: (17/0); baseline: (0/0); (17-0)/(0-0) -> (17/0)
        // numerator has infinite growth relative to denominator
        validateMetricValue(flowMetric, (flowMetricValue) -> {
            assertThat(flowMetricValue, is(not(anEmptyMap())));
            assertThat(flowMetricValue, hasEntry("current", Double.POSITIVE_INFINITY));
            assertThat(flowMetricValue, hasEntry("lifetime", Double.POSITIVE_INFINITY));
        });

        // change denominator, advance clock, capture
        clock.advance(Duration.ofSeconds(1));
        denominatorMetric.set(13);
        flowMetric.capture();

        // both numerator and denominator have changed since baselines
        // now: (17/13); baseline: (0/0); (17-0)/(13-0) -> 1.308 numerators per denominator
        validateMetricValue(flowMetric, (flowMetricValue) -> {
            assertThat(flowMetricValue, is(not(anEmptyMap())));
            assertThat(flowMetricValue, hasEntry("current", 1.308));
            assertThat(flowMetricValue, hasEntry("lifetime", 1.308));
        });

        // our denominator moves and we do a series of captures
        denominatorMetric.set(12);
        for (int i = 0; i < 20; i++) {
            clock.advance(Duration.ofSeconds(1));
            flowMetric.capture();
        }

        // our numerator moves _negative_ relative to the capture from 10s ago.
        clock.advance(Duration.ofSeconds(1));
        numeratorMetric.set(10);
        flowMetric.capture();

        // now: (10/12)
        validateMetricValue(flowMetric, (flowMetricValue) -> {
            assertThat(flowMetricValue, is(not(anEmptyMap())));
            // current window baseline: (17/12); (17-10)/(12-12) -> (-7/0)
            assertThat(flowMetricValue, hasEntry("current", Double.NEGATIVE_INFINITY));
            // lifetime baseline: (0/0); (10-0)/(12-0) -> (10/12)
            assertThat(flowMetricValue, hasEntry("lifetime", 0.8333));
        });
    }

    private <T> void validateMetricValue(final Metric<T> metric, final Consumer<T> validator) {
        validator.accept(metric.getValue());
    }


    private long maxRetentionPlusMinResolutionBuffer(final FlowMetricRetentionPolicy policy) {
        return Math.addExact(policy.retentionNanos(), policy.resolutionNanos());
    }

}