package org.logstash.instrument.metrics;

import org.junit.Test;
import org.logstash.instrument.metrics.counter.LongCounter;

import java.time.Duration;
import java.time.Instant;
import java.util.Map;

import static org.hamcrest.Matchers.*;
import static org.junit.Assert.assertThat;

public class ExtendedFracturedFlowMetricTest {

    @Test
    public void testGetValueSlowCapture() {
        final Number workers = 4;
        final ManualAdvanceClock clock = new ManualAdvanceClock(Instant.now());
        final LongCounter numeratorMetric = new LongCounter(MetricKeys.EVENTS_KEY.asJavaString());
        final Metric<Number> denominatorMetric = new UptimeMetric("uptime", clock::nanoTime).withUnitsPrecise(UptimeMetric.ScaleUnits.SECONDS);
        final ExtendedFlowMetric flowMetric = new ExtendedFracturedFlowMetric(clock::nanoTime, "flow", numeratorMetric, denominatorMetric, workers);

        // capture after 1min
        for(int i = 0; i < 60; i++) {
            clock.advance(Duration.ofSeconds(1));
            numeratorMetric.increment(i);
            flowMetric.capture();
        }

        final Map<String, Double> flowMetricValue = flowMetric.getValue();
        assertThat(flowMetricValue, hasEntry("current",         2.16));
        assertThat(flowMetricValue, hasEntry("last_1_minute",   1.18));
        assertThat(flowMetricValue, hasEntry("lifetime",        1.18));
    }

    @Test
    public void testGetValueOverFlow() {
        final Number workers = 4;
        final ManualAdvanceClock clock = new ManualAdvanceClock(Instant.now());
        final LongCounter numeratorMetric = new LongCounter(MetricKeys.EVENTS_KEY.asJavaString());
        final Metric<Number> denominatorMetric = new UptimeMetric("uptime", clock::nanoTime).withUnitsPrecise(UptimeMetric.ScaleUnits.SECONDS);
        final ExtendedFlowMetric flowMetric = new ExtendedFracturedFlowMetric(clock::nanoTime, "flow", numeratorMetric, denominatorMetric, workers);

        // overflow case: max worker utilization should be workers * 100
        for(int i = 0; i < 100_000; i++) {
            clock.advance(Duration.ofSeconds(1));
            numeratorMetric.increment(i);
            flowMetric.capture();
        }

        final Number maxWorkerUtilizationPercentage = workers.doubleValue() * MetricsUtil.HUNDRED;

        final Map<String, Double> flowMetricValue = flowMetric.getValue();
        assertThat(flowMetricValue, hasEntry("current",         maxWorkerUtilizationPercentage));
        assertThat(flowMetricValue, hasEntry("last_1_minute",   maxWorkerUtilizationPercentage));
        assertThat(flowMetricValue, hasEntry("last_5_minutes",  maxWorkerUtilizationPercentage));
        assertThat(flowMetricValue, hasEntry("last_15_minutes", maxWorkerUtilizationPercentage));
        assertThat(flowMetricValue, hasEntry("last_1_hour",     maxWorkerUtilizationPercentage));
        assertThat(flowMetricValue, hasEntry("last_24_hours",   maxWorkerUtilizationPercentage));
        assertThat(flowMetricValue, hasEntry("lifetime",        maxWorkerUtilizationPercentage));
    }
}