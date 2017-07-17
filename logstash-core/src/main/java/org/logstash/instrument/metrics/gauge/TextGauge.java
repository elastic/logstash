package org.logstash.instrument.metrics.gauge;


import org.logstash.instrument.metrics.AbstractMetric;
import org.logstash.instrument.metrics.MetricType;

import java.util.List;

/**
 * A {@link GaugeMetric} that is backed by a {@link String}
 */
public class TextGauge extends AbstractMetric<String> implements GaugeMetric<String,String> {

    private volatile String value;

    /**
     * Constructor - null initial value
     *
     * @param nameSpace The namespace for this metric
     * @param key       The key <i>(with in the namespace)</i> for this metric
     */
    public TextGauge(List<String> nameSpace, String key) {
        this(nameSpace, key, null);
    }

    /**
     * Constructor
     *
     * @param nameSpace    The namespace for this metric
     * @param key          The key <i>(with in the namespace)</i> for this metric
     * @param initialValue The initial value for this {@link GaugeMetric}, may be null
     */
    public TextGauge(List<String> nameSpace, String key, String initialValue) {
        super(nameSpace, key);
        this.value = initialValue;
    }

    @Override
    public MetricType getType() {
        return MetricType.GAUGE_TEXT;
    }

    @Override
    public String getValue() {
        return value;
    }

    @Override
    public void set(String value) {
        this.value = value;
    }


}