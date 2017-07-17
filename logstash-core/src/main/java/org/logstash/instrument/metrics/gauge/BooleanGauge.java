package org.logstash.instrument.metrics.gauge;

import org.logstash.instrument.metrics.AbstractMetric;
import org.logstash.instrument.metrics.MetricType;
import org.logstash.instrument.metrics.counter.CounterMetric;

import java.util.List;

/**
 * A {@link GaugeMetric} that is backed by a {@link Boolean}
 */
public class BooleanGauge extends AbstractMetric<Boolean> implements GaugeMetric<Boolean,Boolean> {

    private volatile Boolean value;

    /**
     * Constructor - null initial value
     *
     * @param nameSpace    The namespace for this metric
     * @param key          The key <i>(with in the namespace)</i> for this metric
     */
    public BooleanGauge(List<String> nameSpace, String key) {
        this(nameSpace, key, null);
    }

    /**
     * Constructor
     *
     * @param nameSpace    The namespace for this metric
     * @param key          The key <i>(with in the namespace)</i> for this metric
     * @param initialValue The initial value for this {@link GaugeMetric}, may be null
     */
    public BooleanGauge(List<String> nameSpace, String key, Boolean initialValue) {
        super(nameSpace, key);
        this.value = initialValue;
    }

    @Override
    public MetricType getType() {
        return MetricType.GAUGE_BOOLEAN;
    }

    @Override
    public Boolean getValue() {
        return value;
    }

    @Override
    public void set(Boolean value) {
        this.value = value;
    }

}
