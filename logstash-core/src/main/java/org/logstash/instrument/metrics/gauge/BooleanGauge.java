package org.logstash.instrument.metrics.gauge;

import org.logstash.instrument.metrics.MetricType;

/**
 * A {@link GaugeMetric} that is backed by a {@link Boolean}
 */
public class BooleanGauge extends AbstractGaugeMetric<Boolean> {

    /**
     * Constructor - null initial value
     *
     * @param name The name of this metric. This value may be used for display purposes.
     */
    public BooleanGauge(String name) {
        super(name);
    }

    /**
     * Constructor
     *
     * @param name         The name of this metric. This value may be used for display purposes.
     * @param initialValue The initial value for this {@link GaugeMetric}, may be null
     */
    public BooleanGauge(String name, Boolean initialValue) {
        super(name, initialValue);

    }

    @Override
    public MetricType getType() {
        return MetricType.GAUGE_BOOLEAN;
    }

}
