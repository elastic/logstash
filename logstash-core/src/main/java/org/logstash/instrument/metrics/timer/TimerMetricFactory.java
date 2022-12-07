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
        // INTERNAL-ONLY system property escape hatch, set with `metric.timers` config in logstash.yml
        final String timerType = System.getProperty("ls.metric.timers", "delayed");
        switch (timerType) {
            case "live"   : return new ConcurrentLiveTimerMetric(name, nanoTimeSupplier);
            case "delayed": return new AfterCompletionTimerMetric(name, nanoTimeSupplier);
            default       : throw new IllegalStateException(String.format("Unknown timer type `%s`", timerType));
        }
    }
}
