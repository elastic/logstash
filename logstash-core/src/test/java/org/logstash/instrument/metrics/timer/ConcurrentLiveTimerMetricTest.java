package org.logstash.instrument.metrics.timer;

import org.junit.Test;

public class ConcurrentLiveTimerMetricTest extends TimerMetricTest {
    @Override
    TimerMetric initTimerMetric(final String name) {
        return testTimerMetricFactory.newConcurrentLiveTimerMetric(name);
    }

    @Test
    public void testValueDuringConcurrentTrackedExecutions() throws Exception {
        sharedTestWithConcurrentTrackedExecutions(true);
    }
}
