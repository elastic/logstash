package org.logstash.instrument.metrics.counter;

import org.logstash.instrument.metrics.Metric;

/**
 * A {@link Metric} to count things. A counter can only increment, and there are no guarantees of durability of current value between JVM restarts.
 * @param <T> The underlying {@link Number} type that can be incremented. Care should be taken to which {@link Number} is used to back the counter, since some {@link Number}
 *           types may not be appropriate for a monotonic increasing series.
 */
public interface CounterMetric<T extends Number> extends Metric<T> {

    /**
     * Helper method that increments by 1
     */
    void increment();

    /**
     * Increments the counter by the value specified. <i>The caller should be careful to avoid incrementing by values so large as to overflow the underlying type.</i>
     * @param by The value which to increment by.
     */
    void increment(T by) ;
}
