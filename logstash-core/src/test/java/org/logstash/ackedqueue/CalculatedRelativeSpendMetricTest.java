package org.logstash.ackedqueue;

import org.junit.Test;
import org.logstash.instrument.metrics.ManualAdvanceClock;
import org.logstash.instrument.metrics.UptimeMetric;
import org.logstash.instrument.metrics.timer.TestTimerMetricFactory;
import org.logstash.instrument.metrics.timer.TimerMetric;

import java.time.Duration;
import java.time.Instant;

import static org.assertj.core.api.Assertions.assertThat;
import static org.logstash.instrument.metrics.VisibilityUtil.createUptimeMetric;

public class CalculatedRelativeSpendMetricTest {
    @Test
    public void testCalculateRelativeSpendMetric() {
        final ManualAdvanceClock clock = new ManualAdvanceClock(Instant.now());
        final TimerMetric burnMetric = new TestTimerMetricFactory(clock::nanoTime).newTimerMetric("burn");
        final UptimeMetric uptimeMetric = createUptimeMetric("wall", clock::nanoTime);
        final CalculatedRelativeSpendMetric relativeSpendMetric = new CalculatedRelativeSpendMetric("spend", burnMetric, uptimeMetric);

        clock.advance(Duration.ofMillis(17));
        assertThat(relativeSpendMetric.getValue()).isEqualTo(0.0);

        relativeSpendMetric.time(() -> clock.advance(Duration.ofMillis(17)));
        assertThat(relativeSpendMetric.getValue()).isEqualTo(0.5);

        clock.advance(Duration.ofMillis(34));
        assertThat(relativeSpendMetric.getValue()).isEqualTo(0.25);

        relativeSpendMetric.time(() -> clock.advance(Duration.ofMillis(147)));
        assertThat(relativeSpendMetric.getValue()).isEqualTo(0.7628);

        // nesting for forced concurrency; interleaving validated upstream in TimerMetric
        relativeSpendMetric.time(() -> {
            clock.advance(Duration.ofMillis(149));
            relativeSpendMetric.time(() -> clock.advance(Duration.ofMillis(842)));
            clock.advance(Duration.ofMillis(17));
        });
        assertThat(relativeSpendMetric.getValue()).isEqualTo(1.647);

        // advance wall clock without any new timings
        clock.advance(Duration.ofMillis(6833));
        assertThat(relativeSpendMetric.getValue()).isEqualTo(0.25);
    }
}