package org.logstash.instrument.metrics.gauge;


import org.logstash.instrument.metrics.Metric;

/**
 * A {@link Metric} to set/get a value. A Gauge is useful for measuring a single value that may change over time, but does not carry any additional semantics beyond simply setting
 * and getting the value.
 * @param <G> The backing Java type for getting the gauge. For example, a text gauge should return a {@link String}
 * @param <S> The backing Java type for setting the gauge. For example, a text gauge is set with a {@link String}
 */
public interface GaugeMetric<G,S> extends Metric<G> {

    /**
     * Sets the value
     * @param value The value to set
     */
    void set(S value);
}
