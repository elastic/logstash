package org.logstash.instrument.metrics.timer;

import org.logstash.instrument.metrics.TestClock;

import java.util.function.LongSupplier;

/**
 * This {@code TimerMetricFactory} provides factory methods for constructing implementations
 * of {@link TimerMetric} for use in test that are connected to a nano-time supplier (typically
 * {@link TestClock#nanoTime()} from {@link org.logstash.instrument.metrics.ManualAdvanceClock}).
 *
 * <p>The factory methods use the package-private constructors provided by the respective
 * implementations, but are <em>public</em>, which makes them available to other test packages.
 */
public class TimerMetricFactory {
    private final LongSupplier nanoTimeSupplier;

    public TimerMetricFactory(TestClock testClock) {
        this(testClock::nanoTime);
    }

    public TimerMetricFactory(final LongSupplier nanoTimeSupplier) {
        this.nanoTimeSupplier = nanoTimeSupplier;
    }

    public AfterCompletionTimerMetric newAfterCompletionTimerMetric(final String name) {
        return new AfterCompletionTimerMetric(name, this.nanoTimeSupplier);
    }

    public ConcurrentLiveTimerMetric newConcurrentLiveTimerMetric(final String name) {
        return new ConcurrentLiveTimerMetric(name, this.nanoTimeSupplier);
    }
}
