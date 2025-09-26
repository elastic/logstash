package org.logstash.instrument.metrics.timer;

import org.logstash.instrument.metrics.AbstractMetric;

import java.util.Objects;
import java.util.concurrent.atomic.AtomicReference;
import java.util.concurrent.atomic.LongAdder;
import java.util.function.LongSupplier;

import static org.logstash.instrument.metrics.timer.Util.subMilliExcessNanos;
import static org.logstash.instrument.metrics.timer.Util.wholeMillisFromNanos;

/**
 * This {@code ConcurrentLiveTimerMetric} tracks live concurrent execution.
 * It is concurrency-safe and lock-free.
 *
 * <p>It works by keeping track of a {@code TrackedMillisState}, which contains
 * a timestamped checkpoint since which concurrency has been constant. From this
 * checkpoint the cumulative concurrently-elapsed time can be calculated.
 *
 * <p>When concurrency increases or decreases, the checkpoint is atomically replaced.
 *
 * <p>It separately records untracked millis.</p>
 */
public class ConcurrentLiveTimerMetric extends AbstractMetric<Long> implements TimerMetric {

    private final LongAdder untrackedMillis = new LongAdder();

    private final AtomicReference<TrackedMillisState> trackedMillisState;

    private final LongSupplier nanoTimeSupplier;

    protected ConcurrentLiveTimerMetric(final String name) {
        this(name, System::nanoTime);
    }

    ConcurrentLiveTimerMetric(final String name, final LongSupplier nanoTimeSupplier) {
        super(name);
        this.nanoTimeSupplier = Objects.requireNonNullElse(nanoTimeSupplier, System::nanoTime);
        this.trackedMillisState = new AtomicReference<>(new StaticTrackedMillisState());
    }

    @Override
    public <T, E extends Throwable> T time(ExceptionalSupplier<T, E> exceptionalSupplier) throws E {
        try {
            trackedMillisState.getAndUpdate(existing -> existing.withIncrementedConcurrency(nanoTimeSupplier.getAsLong()));
            return exceptionalSupplier.get();
        } finally {
            // lock in the actual time completed, and resolve state separately
            // so that contention for recording state is not included in measurement.
            final long endTime = nanoTimeSupplier.getAsLong();
            trackedMillisState.getAndUpdate(existing -> existing.withDecrementedConcurrency(endTime));
        }
    }

    @Override
    public void reportUntrackedMillis(final long untrackedMillis) {
        this.untrackedMillis.add(untrackedMillis);
    }

    @Override
    public Long getValue() {
        return Math.addExact(getUntrackedMillis(), getTrackedMillis());
    }

    private long getUntrackedMillis() {
        return this.untrackedMillis.longValue();
    }

    private long getTrackedMillis() {
        return this.trackedMillisState.getAcquire().getValue(nanoTimeSupplier.getAsLong());
    }

    interface TrackedMillisState {
        TrackedMillisState withIncrementedConcurrency(long asOfNanoTime);
        TrackedMillisState withDecrementedConcurrency(long asOfNanoTime);
        long getValue(long asOfNanoTime);
    }

    private class StaticTrackedMillisState implements TrackedMillisState {
        private final long cumulativeMillis;
        private final int excessNanos;

        StaticTrackedMillisState(final long cumulativeMillis,
                                 final int excessNanos) {
            this.cumulativeMillis = cumulativeMillis;
            this.excessNanos = excessNanos;
        }

        public StaticTrackedMillisState() {
            this(0L, 0);
        }

        @Override
        public TrackedMillisState withIncrementedConcurrency(final long asOfNanoTime) {
            return new DynamicTrackedMillisState(asOfNanoTime, this.cumulativeMillis, this.excessNanos, 1);
        }

        @Override
        public TrackedMillisState withDecrementedConcurrency(final long asOfNanoTime) {
            throw new IllegalStateException("TimerMetrics cannot track negative concurrency");
        }


        @Override
        public long getValue(final long asOfNanoTime) {
            return cumulativeMillis;
        }
    }

    private class DynamicTrackedMillisState implements TrackedMillisState {
        private final long checkpointNanoTime;
        private final long millisAtCheckpoint;
        private final int excessNanosAtCheckpoint;
        private final int concurrencySinceCheckpoint;

        DynamicTrackedMillisState(long checkpointNanoTime,
                                  long millisAtCheckpoint,
                                  int excessNanosAtCheckpoint,
                                  int concurrencySinceCheckpoint) {
            this.checkpointNanoTime = checkpointNanoTime;
            this.millisAtCheckpoint = millisAtCheckpoint;
            this.excessNanosAtCheckpoint = excessNanosAtCheckpoint;
            this.concurrencySinceCheckpoint = concurrencySinceCheckpoint;
        }

        @Override
        public TrackedMillisState withIncrementedConcurrency(final long asOfNanoTime) {
            return withAdjustedConcurrency(asOfNanoTime, Vector.INCREMENT);
        }

        @Override
        public TrackedMillisState withDecrementedConcurrency(final long asOfNanoTime) {
            return withAdjustedConcurrency(asOfNanoTime, Vector.DECREMENT);
        }

        @Override
        public long getValue(final long asOfNanoTime) {
            final long nanoAdjustment = getNanoAdjustment(asOfNanoTime);
            final long milliAdjustment = wholeMillisFromNanos(nanoAdjustment);

            return Math.addExact(this.millisAtCheckpoint, milliAdjustment);
        }

        private TrackedMillisState withAdjustedConcurrency(final long asOfNanoTime, final Vector concurrencyAdjustmentVector) {
            final int newConcurrency = Math.addExact(this.concurrencySinceCheckpoint, concurrencyAdjustmentVector.value());
            final long newCheckpointNanoTime = asOfNanoTime;

            final long totalNanoAdjustment = getNanoAdjustment(newCheckpointNanoTime);

            final long newCheckpointMillis = Math.addExact(this.millisAtCheckpoint, wholeMillisFromNanos(totalNanoAdjustment));
            final int newCheckpointExcessNanos = subMilliExcessNanos(totalNanoAdjustment);

            if (newConcurrency <= 0) {
                return new StaticTrackedMillisState(newCheckpointMillis, newCheckpointExcessNanos);
            } else {
                return new DynamicTrackedMillisState(newCheckpointNanoTime, newCheckpointMillis, newCheckpointExcessNanos, newConcurrency);
            }
        }

        private long getNanoAdjustment(final long checkpointNanoTime) {
            final long deltaNanoTime = Math.subtractExact(checkpointNanoTime, this.checkpointNanoTime);
            final long calculatedNanoAdjustment = Math.multiplyExact(deltaNanoTime, this.concurrencySinceCheckpoint);

            return Math.addExact(calculatedNanoAdjustment, this.excessNanosAtCheckpoint);
        }
    }

    /**
     * This private enum is a type-safety guard for
     * {@link DynamicTrackedMillisState#withAdjustedConcurrency(long, Vector)}.
     */
    private enum Vector {
        INCREMENT{ int value() { return +1; } },
        DECREMENT{ int value() { return -1; } };

        abstract int value();
    }
}
