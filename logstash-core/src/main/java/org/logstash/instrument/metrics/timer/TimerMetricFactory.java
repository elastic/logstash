package org.logstash.instrument.metrics.timer;

import java.util.function.LongSupplier;

public class TimerMetricFactory {
    static final TimerMetricFactory INSTANCE = new TimerMetricFactory();

    private TimerMetricFactory() {
    }

    public TimerMetric create(final String name) {
        return create(name, System::nanoTime);
    }

    TimerMetric create(final String name, final LongSupplier nanoTimeSupplier) {
        return new ConcurrentLiveTimerMetric(name, nanoTimeSupplier);
    }
}
