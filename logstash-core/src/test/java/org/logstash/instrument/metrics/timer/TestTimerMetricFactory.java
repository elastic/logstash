package org.logstash.instrument.metrics.timer;

import org.logstash.instrument.metrics.TestClock;

import java.util.function.LongSupplier;

/**
 * This {@code TestTimerMetricFactory} provides factory methods for constructing implementations
 * of {@link TimerMetric} for use in test that are connected to a nano-time supplier (typically
 * {@link TestClock#nanoTime()} from {@link org.logstash.instrument.metrics.ManualAdvanceClock}).
 *
 * <p>The factory methods use the package-private constructors provided by the respective
 * implementations, but are <em>public</em>, which makes them available to other test packages.
 */
public class TestTimerMetricFactory {
    private final LongSupplier nanoTimeSupplier;

    public TestTimerMetricFactory(TestClock testClock) {
        this(testClock::nanoTime);
    }

    public TestTimerMetricFactory(final LongSupplier nanoTimeSupplier) {
        this.nanoTimeSupplier = nanoTimeSupplier;
    }

    public ConcurrentLiveTimerMetric newConcurrentLiveTimerMetric(final String name) {
        return new ConcurrentLiveTimerMetric(name, this.nanoTimeSupplier);
    }

    public TimerMetric newTimerMetric(final String name) {
        return TimerMetricFactory.INSTANCE.create(name, this.nanoTimeSupplier);
    }
}
