package org.logstash.instrument.metrics.timer;

import org.logstash.instrument.metrics.AbstractMetric;
import org.logstash.instrument.metrics.MetricType;

import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.LongAdder;
import java.util.function.LongSupplier;

/**
 * This {@code AfterCompletionTimerMetric} is based on a counter,
 * which is incremented after tracked execution is complete.
 */
public class AfterCompletionTimerMetric extends AbstractMetric<Long> implements TimerMetric {
    private final LongAdder longAdder = new LongAdder();

    private final LongSupplier nanoTimeSupplier;

    protected AfterCompletionTimerMetric(String name) {
        this(name, System::nanoTime);
    }

    AfterCompletionTimerMetric(final String name,
                               final LongSupplier nanoTimeSupplier) {
        super(name);
        this.nanoTimeSupplier = nanoTimeSupplier;
    }

    @Override
    public <T, E extends Throwable> T time(ExceptionalSupplier<T, E> exceptionalSupplier) throws E {
        final long startNanos = this.nanoTimeSupplier.getAsLong();
        try {
            return exceptionalSupplier.get();
        } finally {
            final long durationNanos = this.nanoTimeSupplier.getAsLong() - startNanos;
            final long durationMillis = TimeUnit.NANOSECONDS.toMillis(durationNanos);

            this.reportMillisElapsed(durationMillis);
        }
    }

    @Override
    public void reportUntrackedMillis(final long untrackedMillis) {
        reportMillisElapsed(untrackedMillis);
    }

    private void reportMillisElapsed(final long millisElapsed) {
        this.longAdder.add(millisElapsed);
    }

    @Override
    public MetricType getType() {
        return MetricType.TIMER_LONG;
    }

    @Override
    public Long getValue() {
        return this.longAdder.sum();
    }
}
