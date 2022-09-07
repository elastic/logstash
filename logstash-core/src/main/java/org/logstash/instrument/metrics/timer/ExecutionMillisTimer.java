package org.logstash.instrument.metrics.timer;

import co.elastic.logstash.api.TimerMetric;
import org.jruby.RubySymbol;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.instrument.metrics.AbstractMetric;
import org.logstash.instrument.metrics.AbstractNamespacedMetricExt;
import org.logstash.instrument.metrics.MetricType;

import java.util.Objects;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicReference;
import java.util.concurrent.atomic.LongAdder;
import java.util.function.LongSupplier;
import java.util.function.Supplier;

/**
 * An {@link ExecutionMillisTimer}'s value tracks the _cumulative_ execution time,
 * including concurrent in-flight execution. The implementation is threadsafe and non-blocking.
 *
 * <p>It does so by keeping track of untracked and tracked elapsed time separately,
 * with the tracked adjustment capable of calculating the elapsed time since its last checkpoint,
 * during which it has had constant concurrency.
 */
public class ExecutionMillisTimer extends AbstractMetric<Long> implements TimerMetric {

    private final LongAdder untrackedMillis = new LongAdder();
    private final AtomicReference<MillisAdjustmentState> trackedMillisAdjustment;

    // test-only dependency injection
    private final LongSupplier nanoTimeSupplier;

    private static final ExecutionMillisTimer NULL_TIMER = new ExecutionMillisTimer("null_timer"){
        @Override public <R> R time(Supplier<R> supplier) { return supplier.get(); }
        @Override public ExecutionCommitter begin() { return new ExecutionCommitter(System.nanoTime(), System::nanoTime); }
        @Override public void reportUntracked(long millis) {}
        @Override public Long getValue() { return 0L; }
    };

    public static ExecutionMillisTimer nullTimer() {
        return NULL_TIMER;
    }

    public ExecutionMillisTimer(final String name) {
        this(System::nanoTime, name);
    }

    ExecutionMillisTimer(final LongSupplier nanoTimeSupplier, final String name) {
        super(name);
        this.nanoTimeSupplier = Objects.requireNonNullElse(nanoTimeSupplier, System::nanoTime);
        this.trackedMillisAdjustment = new AtomicReference<>(new StaticAdjustmentState());
    }

    @Override
    public <R> R time(final Supplier<R> supplier){
        final ExecutionCommitter executionCommitter = begin();
        try {
            return supplier.get();
        } finally {
            executionCommitter.commit();
        }
    }

    @Override
    public ExecutionCommitter begin() {
        final long newCheckpointNanos = trackedMillisAdjustment.updateAndGet(MillisAdjustmentState::withIncrementedConcurrency).getCheckpointNanoTime();
        return new ExecutionCommitter(newCheckpointNanos, () -> trackedMillisAdjustment.updateAndGet(MillisAdjustmentState::withDecrementedConcurrency).getCheckpointNanoTime());
    }

    @Override
    public void reportUntracked(final long millis) {
        untrackedMillis.add(millis);
    }

    @Override
    public MetricType getType() {
        return MetricType.COUNTER_LONG;
    }

    @Override
    public Long getValue() {
        return trackedMillisAdjustment.get().adjust(untrackedMillis.longValue());
    }

    public static ExecutionMillisTimer fromRubyBase(final AbstractNamespacedMetricExt metric,
                                                    final RubySymbol key) {
        final ThreadContext context = RubyUtil.RUBY.getCurrentContext();
        final IRubyObject timer = metric.timer(context, key);

        if (ExecutionMillisTimer.class.isAssignableFrom(timer.getJavaClass())) {
            return timer.toJava(ExecutionMillisTimer.class);
        } else {
            return NULL_TIMER;
        }
    }

    static class ExecutionCommitter implements Committer {
        private final long startNanos;
        private final LongSupplier atomicCommitAction;
        private final AtomicBoolean committed = new AtomicBoolean(false);

        /**
         *
         * @param startNanos a marker for the start time
         * @param atomicCommitAction an action that will be executed exactly once,
         *                           which returns the number of NANOSECONDS since the provided start time.
         */
        ExecutionCommitter(final long startNanos, final LongSupplier atomicCommitAction) {
            this.startNanos = startNanos;
            this.atomicCommitAction = atomicCommitAction;
        }
        @Override
        public long commit() {
            if (committed.compareAndSet(false, true)) {
                final long commitNanos = atomicCommitAction.getAsLong();
                return TimeUnit.NANOSECONDS.toMillis(commitNanos - this.startNanos);
            } else {
                return 0L;
            }
        }
    }

    interface MillisAdjustmentState {
        long getCheckpointNanoTime();
        MillisAdjustmentState withIncrementedConcurrency();
        MillisAdjustmentState withDecrementedConcurrency();
        long adjust(long externalMillis);
    }

    /**
     * A {@link StaticAdjustmentState} is static, in that it is not tracking
     * any concurrent executions, which makes calculations static and enables
     * us to guard against negative concurrency.
     */
    private class StaticAdjustmentState implements MillisAdjustmentState {
        private final long checkpointNanos;
        private final long cumulativeMillis;
        private final long excessNanos;

        public StaticAdjustmentState(final long checkpointNanos, final long cumulativeMillis, final long excessNanos) {
            this.checkpointNanos = checkpointNanos;
            this.cumulativeMillis = cumulativeMillis + Math.floorDiv(excessNanos, 1_000_000);
            this.excessNanos = Math.floorMod(excessNanos, 1_000_000);
        }

        public StaticAdjustmentState() {
            this(nanoTimeSupplier.getAsLong(), 0L, 0L);
        }

        @Override
        public DynamicAdjustmentState withIncrementedConcurrency() {
            return new DynamicAdjustmentState(cumulativeMillis, excessNanos);
        }

        @Override
        public MillisAdjustmentState withDecrementedConcurrency() {
            throw new IllegalStateException("Timers cannot track negative concurrency");
        }

        @Override
        public long adjust(final long externalMillis) {
            return Math.addExact(externalMillis, this.cumulativeMillis);
        }

        @Override
        public long getCheckpointNanoTime() {
            return this.checkpointNanos;
        }
    }

    /**
     * An {@link DynamicAdjustmentState} is actively tracking execution with
     * a non-zero concurrency. It holds sufficient information to mark a checkpoint,
     * along with a known constant concurrency since that checkpoint, so that it can
     * calculate the elapsed execution time of in-flight executions.
     *
     * <p>For example, if we are tracking N concurrent executions, our calculated value
     * will be the value at our checkpoint plus N times the duration since that
     * checkpoint.
     */
    private class DynamicAdjustmentState implements MillisAdjustmentState {
        private final long checkpointNanoTime;
        private final long committedMillis;
        private final long committedExcessNanos;
        private final int concurrency;
        public DynamicAdjustmentState(final long committedMillis, final long committedExcessNanos) {
            this(nanoTimeSupplier.getAsLong(), committedMillis, committedExcessNanos, 1);
        }
        private DynamicAdjustmentState(final long checkpointNanoTime,
                                       final long committedMillis,
                                       final long committedExcessNanos,
                                       final int concurrency) {
            this.checkpointNanoTime = checkpointNanoTime;
            this.committedMillis = committedMillis + Math.floorDiv(committedExcessNanos, 1_000_000);
            this.committedExcessNanos = Math.floorMod(committedExcessNanos, 1_000_000);
            this.concurrency = concurrency;
        }

        @Override
        public MillisAdjustmentState withIncrementedConcurrency() {
            return adjustConcurrency(+1);
        }

        @Override
        public MillisAdjustmentState withDecrementedConcurrency() {
            return adjustConcurrency(-1);
        }

        @Override
        public long getCheckpointNanoTime() {
            return this.checkpointNanoTime;
        }

        @Override
        public long adjust(final long externalMillis) {
            final long excessNanos = calculateExcessNanos(nanoTimeSupplier.getAsLong());
            final long excessMillis = TimeUnit.NANOSECONDS.toMillis(excessNanos);

            final long dynamicMillis = Math.addExact(this.committedMillis, excessMillis);
            return Math.addExact(externalMillis, dynamicMillis);
        }

        private MillisAdjustmentState adjustConcurrency(final int vector) {
            final long newCheckpointNanoTime = nanoTimeSupplier.getAsLong();
            final int newConcurrency = this.concurrency + vector;
            final long excessNanos = calculateExcessNanos(newCheckpointNanoTime);

            if (newConcurrency == 0) {
                return new StaticAdjustmentState(newCheckpointNanoTime, this.committedMillis, excessNanos);
            }
            return new DynamicAdjustmentState(newCheckpointNanoTime, this.committedMillis, excessNanos, newConcurrency);
        }

        private long calculateExcessNanos(long proposedCheckpointNanoTime) {
            final long deltaNanoTime = Math.subtractExact(proposedCheckpointNanoTime, this.checkpointNanoTime);
            final long calculatedExcessNanos = Math.multiplyExact(deltaNanoTime, this.concurrency);

            return Math.addExact(this.committedExcessNanos, calculatedExcessNanos);
        }
    }
}
