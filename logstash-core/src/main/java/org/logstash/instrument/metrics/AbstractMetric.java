package org.logstash.instrument.metrics;


import com.fasterxml.jackson.annotation.JsonValue;

import java.util.Arrays;
import java.util.List;

/**
 * Abstract implementation of a {@link Metric}. All metrics should subclass this.
 *
 * @param <T> The underlying type for this metric. For example {@link Long} for Counter, or {@link String} for Gauge.
 */
public abstract class AbstractMetric<T> implements Metric<T> {
    final protected String key;
    final protected List<String> nameSpace;

    /**
     * Constructor
     *
     * @param nameSpace The namespace for this metric
     * @param key       The key <i>(with in the namespace)</i> for this metric
     */
    protected AbstractMetric(final List<String> nameSpace, final String key) {
        this.nameSpace = nameSpace;
        this.key = key;
    }

    @Override
    public abstract MetricType getType();

    @JsonValue
    public abstract T getValue();

    @Override
    public String toString() {
        return String.format("%s - namespace: %s key: %s value:%s", this.getClass().getName(), Arrays.toString(nameSpace.toArray()), this.key, getValue() == null ? "null" :
                getValue().toString());
    }

    @Override
    public List<String> getNameSpaces() {
        return this.nameSpace;
    }

    @Override
    public String getKey() {
        return this.key;
    }

}
