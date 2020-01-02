package co.elastic.logstash.api;

import java.util.function.Supplier;

/**
 * Represents a nested namespace that metrics can be written into and other namespaces
 * can be nested within.
 */
public interface NamespacedMetric extends Metric {
    /**
     * Writes an absolute value to the {@code metric}.
     *
     * @param metric metric to write value to
     * @param value value to write
     */
    void gauge(String metric, Object value);

    /**
     * Creates a counter with the name {@code metric}.
     *
     * @param metric name of the counter
     * @return an instance tracking a counter metric allowing easy incrementing and resetting
     */
    CounterMetric counter(String metric);

    /**
     * Increment the {@code metric} metric by 1.
     *
     * @param metric metric to increment
     */
    void increment(String metric);

    /**
     * Increment the {@code metric} by {@code delta}.
     *
     * @param metric metric to increment
     * @param delta amount to increment by
     */
    void increment(String metric, int delta);

    /**
     * Times the {@code callable} and returns its value and increments the
     * {@code metric} with the time taken.
     *
     * @param metric metric to increment
     * @param callable callable to time
     * @param <T> return type of the {@code callable}
     * @return the return value from the {@code callable}
     */
    <T> T time(String metric, Supplier<T> callable);

    /**
     * Increments the {@code metric} by {@code duration}.
     *
     * @param metric metric to increment
     * @param duration duration to increment by
     */
    void reportTime(String metric, long duration);

    /**
     * Retrieves each namespace component that makes up this metric.
     *
     * @return the namespaces this metric is nested within
     */
    String[] namespaceName();

    /**
     * Gets Logstash's root metric namespace.
     *
     * @return the root namespace
     */
    Metric root();
}
