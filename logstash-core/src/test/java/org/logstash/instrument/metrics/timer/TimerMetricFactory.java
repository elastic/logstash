package org.logstash.instrument.metrics.timer;

import org.logstash.instrument.metrics.TestClock;

/**
 * This {@code TimerMetricFactory} provides factory methods for constructing implementations
 * of {@link TimerMetric} for use in test that are connected to a {@link TestClock}
 * (typically {@link org.logstash.instrument.metrics.ManualAdvanceClock}).
 *
 * <p>The factory methods use the package-private constructors provided by the respective
 * implementations, but are <em>public</em>, which makes them available to other test packages.
 */
public class TimerMetricFactory {
    private final TestClock testClock;

    public TimerMetricFactory(TestClock testClock) {
        this.testClock = testClock;
    }

    public AfterCompletionTimerMetric newAfterCompletionTimerMetric(final String name) {
        return new AfterCompletionTimerMetric(name, this.testClock::nanoTime);
    }

    public ConcurrentLiveTimerMetric newConcurrentLiveTimerMetric(final String name) {
        return new ConcurrentLiveTimerMetric(name, this.testClock::nanoTime);
    }
}
