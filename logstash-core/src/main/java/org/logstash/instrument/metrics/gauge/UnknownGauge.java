package org.logstash.instrument.metrics.gauge;

import org.logstash.instrument.metrics.AbstractMetric;
import org.logstash.instrument.metrics.MetricType;

import java.util.List;

/**
 * A {@link GaugeMetric} that is backed by a {@link Object}.  Note - A stronger typed {@link GaugeMetric} should be used since this makes no guarantees of serializing properly.
 */
public class UnknownGauge extends AbstractMetric<Object> implements GaugeMetric<Object,Object> {

    private volatile Object value;

    /**
     * Constructor - null initial value
     *
     * @param nameSpace    The namespace for this metric
     * @param key          The key <i>(with in the namespace)</i> for this metric
     */
    public UnknownGauge(List<String> nameSpace, String key) {
        this(nameSpace, key, null);
    }

    /**
     * Constructor
     *
     * @param nameSpace    The namespace for this metric
     * @param key          The key <i>(with in the namespace)</i> for this metric
     * @param initialValue The initial value for this {@link GaugeMetric}, may be null
     */
    public UnknownGauge(List<String> nameSpace, String key, Object initialValue) {
        super(nameSpace, key);
        this.value = initialValue;
    }

    @Override
    public MetricType getType() {
        return MetricType.GAUGE_UNKNOWN;
    }

    @Override
    public Object getValue() {
        return value;
    }

    @Override
    public void set(Object value) {
        this.value = value;
    }

}
