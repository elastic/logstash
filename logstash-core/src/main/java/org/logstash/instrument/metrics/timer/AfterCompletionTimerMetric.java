package org.logstash.instrument.metrics.timer;

import org.logstash.instrument.metrics.AbstractMetric;

import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.LongAdder;
import java.util.function.LongSupplier;

import static org.logstash.instrument.metrics.timer.Util.subMilliExcessNanos;
import static org.logstash.instrument.metrics.timer.Util.wholeMillisFromNanos;

/**
 * This {@code AfterCompletionTimerMetric} is based on a counter,
 * which is incremented after tracked execution is complete.
 */
public class AfterCompletionTimerMetric extends AbstractMetric<Long> implements TimerMetric {
    private final LongAdder millis = new LongAdder();
    private final LongAdder excessNanos = new LongAdder();

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
            this.reportNanosElapsed(durationNanos);
        }
    }

    @Override
    public void reportUntrackedMillis(final long untrackedMillis) {
        this.millis.add(untrackedMillis);
    }

    private void reportNanosElapsed(final long nanosElapsed) {
        long wholeMillis = wholeMillisFromNanos(nanosElapsed);
        long excessNanos = subMilliExcessNanos(nanosElapsed);

        this.millis.add(wholeMillis);
        this.excessNanos.add(excessNanos);
    }

    @Override
    public Long getValue() {
        final long wholeMillis = this.millis.sum();
        final long millisFromNanos = wholeMillisFromNanos(this.excessNanos.sum());
        return Math.addExact(wholeMillis, millisFromNanos);
    }
}
