package co.elastic.logstash.api;

import java.util.function.Supplier;

/**
 * A timer metric that tracks a single timer.
 *
 * You can retrieve an instance of this class using {@link NamespacedMetric#timer(String)}.
 */
public interface TimerMetric {
    /**
     * Execute the provided {@link Supplier}, timing its execution.
     * @param supplier a block for execution
     * @return the value of executing the {@code supplier} without modification
     * @param <R> this method returns an object of the same type as the one supplied by {@code supplier}
     */
    <R> R time(Supplier<R> supplier);

    /**
     * For cases where it is NOT practical to use {@link TimerMetric#time(Supplier)},
     * but IS practical to guarantee we can commit execution after completion with {@link Committer#commit()}.
     *
     * @return a {@link Committer}, which is used for stopping the timer.
     *         when using {@link TimerMetric#begin()}, you <em>MUST</em> also send {@link Committer#commit()}.
     */
    Committer begin();

    /**
     * Report a number of milliseconds elapsed <em>without</em> tracking execution itself.
     * This is significantly safer than {@link TimerMetric#begin()}+{@link Committer#commit()}.
     * @param millisecondsElapsed
     */
    void reportUntracked(final long millisecondsElapsed);

    interface Committer {
        /**
         * @return the number of milliseconds since instantiation
         */
        long commit();
    }
}
