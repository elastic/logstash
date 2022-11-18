package co.elastic.logstash.api;

import java.io.IOException;
import java.util.function.Supplier;

/**
 * This {@code TimerMetric} is a write-only interface for timing execution.
 *
 * <p>It includes two primary methods of tracking timed execution:
 * <dl>
 *     <dt>{@link TimerMetric#time}</dt>
 *     <dd>Track the execution time of the provided block or closure.
 *         This is the preferred method, as it requires no math or
 *         external time-tracking.</dd>
 *     <dt>{@link TimerMetric#reportUntrackedMillis}</dt>
 *     <dd>Report milliseconds elapsed that were <em>NOt</em> tracked.
 *         This method requires provisioning your own time source
 *         (typically {@link System#nanoTime()}) and performing your
 *         own time conversion math.</dd>
 * </dl>
 *
 * A namespaced instance of {@code TimerMetric} can be acquired by plugins
 * using {@link NamespacedMetric#timer(String)}, or can be invoked directly
 * from a metric namespace with {@link NamespacedMetric#time(String, Supplier)}
 * or {@link NamespacedMetric#reportTime(String, long)}.
 */
public interface TimerMetric {
    <T, E extends Throwable> T time(ExceptionalSupplier<T, E> exceptionalSupplier) throws E;

    void reportUntrackedMillis(final long untrackedMillis);


    default <E extends Throwable> void time(final ExceptionalRunnable<E> exceptionalRunnable) throws E {
        this.<Void, E>time(() -> {
            exceptionalRunnable.run();
            return null;
        });
    }

    @FunctionalInterface
    interface ExceptionalSupplier<T,E extends Throwable> {
        T get() throws E;
    }

    @FunctionalInterface
    interface ExceptionalRunnable<E extends Throwable> {
        void run() throws E;
    }
}
