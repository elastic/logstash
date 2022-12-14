package org.logstash.instrument.metrics.timer;

/**
 * This {@code NullTimerMetric} is adheres to our internal {@link TimerMetric}
 * interface, but does not keep track of execution time. It is used as a stand-in
 * when metrics are disabled.
 */
public class NullTimerMetric implements TimerMetric {
    private static final TimerMetric INSTANCE = new NullTimerMetric();

    public static TimerMetric getInstance() { return INSTANCE; }

    private NullTimerMetric() { }

    @Override
    public <T, E extends Throwable> T time(ExceptionalSupplier<T, E> exceptionalSupplier) throws E {
        return exceptionalSupplier.get();
    }

    @Override
    public void reportUntrackedMillis(long untrackedMillis) {
        // no-op
    }

    @Override
    public String getName() {
        return "NULL";
    }

    @Override
    public Long getValue() {
        return 0L;
    }
}
