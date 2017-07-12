package org.logstash.instrument.metrics.gauge;


import org.logstash.instrument.metrics.Metric;

/**
 * A {@link Metric} to set/get a value. A Gauge is useful for measuring a single value that may change over time, but does not carry any additional semantics beyond simply setting
 * and getting the value.
 * @param <T> The backing Java type for the gauge. For example, a text gauge is backed by a {@link String}
 */
public interface GaugeMetric<T> extends Metric<T> {

    /**
     * Sets the value
     * @param value The value to set
     */
    void set(T value);
}
