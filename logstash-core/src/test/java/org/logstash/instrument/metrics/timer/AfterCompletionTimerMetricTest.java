package org.logstash.instrument.metrics.timer;

import org.logstash.instrument.metrics.ManualAdvanceClock;

import java.time.Instant;

public class AfterCompletionTimerMetricTest extends TimerMetricTest {

    private final ManualAdvanceClock manualAdvanceClock;
    private final AfterCompletionTimerMetric timerMetric;

    public AfterCompletionTimerMetricTest() {
        this.manualAdvanceClock = new ManualAdvanceClock(Instant.now());

        final TestTimerMetricFactory testTimerMetricFactory = new TestTimerMetricFactory(manualAdvanceClock);
        this.timerMetric = testTimerMetricFactory.newAfterCompletionTimerMetric("duration_in_millis");
    }

    @Override
    ManualAdvanceClock getClock() {
        return manualAdvanceClock;
    }

    @Override
    TimerMetric getTimerMetric() {
        return timerMetric;
    }
}
