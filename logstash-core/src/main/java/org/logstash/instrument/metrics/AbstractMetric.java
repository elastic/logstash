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
    final protected String name;

    /**
     * Constructor
     *
     * @param name The name of this metric. This value may be used for display purposes.
     */
    protected AbstractMetric(final String name) {
        this.name = name;
    }

    @Override
    public abstract MetricType getType();

    @JsonValue
    public abstract T getValue();

    @Override
    public String toString() {
        return String.format("%s -  name: %s value:%s", this.getClass().getName(), this.name, getValue() == null ? "null" :
                getValue().toString());
    }

    @Override
    public String getName() {
        return this.name;
    }

}
