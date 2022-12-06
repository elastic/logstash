package org.logstash.instrument.metrics.timer;

public class ConcurrentLiveTimerMetricTest extends TimerMetricTest {
    @Override
    TimerMetric initTimerMetric(final String name) {
        return timerMetricFactory.newConcurrentLiveTimerMetric(name);
    }
}
