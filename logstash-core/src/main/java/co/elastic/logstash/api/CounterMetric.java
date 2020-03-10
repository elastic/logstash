package co.elastic.logstash.api;

/**
 * A counter metric that tracks a single counter.
 *
 * You can retrieve an instance of this class using {@link NamespacedMetric#counter(String)}.
 */
public interface CounterMetric {
    /**
     * Increments the counter by 1.
     */
    void increment();

    /**
     * Increments the counter by {@code delta}.
     *
     * @param delta amount to increment the counter by
     */
    void increment(long delta);

    /**
     * Gets the current value of the counter.
     *
     * @return the counter value
     */
    long getValue();

    /**
     * Sets the counter back to 0.
     */
    void reset();
}
