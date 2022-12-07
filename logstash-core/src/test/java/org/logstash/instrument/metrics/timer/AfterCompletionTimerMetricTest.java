package org.logstash.instrument.metrics.timer;

public class AfterCompletionTimerMetricTest extends TimerMetricTest {
    @Override
    TimerMetric initTimerMetric(final String name) {
        return testTimerMetricFactory.newAfterCompletionTimerMetric(name);
    }
}
