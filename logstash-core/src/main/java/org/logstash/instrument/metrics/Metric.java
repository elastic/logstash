package org.logstash.instrument.metrics;

/**
 * Top level contract for metrics within Logstash.
 *
 * @param <T> The underlying type for this metric. For example {@link Long} for Counter, or {@link String} for Gauge.
 * @since 6.0
 */
public interface Metric<T> {

    /**
     * This metric's name. May be used for display purposes.
     *
     * @return The name of this metric.
     */
    String getName();

    /**
     * This should be equal to #getValue, exists for passivity with legacy Ruby code. Java consumers should use #getValue().
     *
     * @return This metric value
     * @deprecated
     */
    default T get() {
        return getValue();
    }

    /**
     * The enumerated Metric Type. This is a semantic type <i>(not Java type)</i> that can be useful to help identify the type of Metric. For example "counter/long".
     *
     * @return The {@link MetricType} that this metric represents.
     */
    MetricType getType();

    /**
     * Retrieves the value associated with this metric
     *
     * @return This metric value
     */
    T getValue();

    /**
     * This may be equal to the #toString method, exists for passivity with legacy Ruby code. Java consumers should use #toString
     *
     * @return A description of this Metric that can be used for logging.
     * @deprecated
     */
    default String inspect() {
        return toString();
    }

    /**
     * This should be equal to {@link MetricType#asString()}, exists for passivity with legacy Ruby code. Java consumers should use #getType().
     *
     * @return The {@link String} version of the {@link MetricType}
     * @deprecated
     */
    default String type() {
        return getType().asString();
    }

    /**
     * Determine if this metric has a value explicitly set.
     * @return true if this metric has been set to a specific value, false if it is the default state
     * @deprecated - This will be removed in the next release.
     */
    boolean isDirty();

    /**
     * Sets the dirty state of this metric. A metric is dirty if it is anything other then it's default state.
     *
     * @param dirty the dirty state
     * @deprecated - This will be removed in the next release.
     */
    void setDirty(boolean dirty);
}
