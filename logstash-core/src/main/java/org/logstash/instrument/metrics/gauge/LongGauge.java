package org.logstash.instrument.metrics.gauge;

import org.logstash.instrument.metrics.MetricType;

/**
 * A {@link GaugeMetric} that is backed by a {@link Long}
 */
public class LongGauge extends AbstractGaugeMetric<Long> {


    /**
     * Constructor
     *
     * @param name The name of this metric. This value may be used for display purposes.
     */
    public LongGauge(String name) {
        super(name);
    }

    /**
     * Constructor
     *
     * @param name         The name of this metric. This value may be used for display purposes.
     * @param initialValue The initial value for this {@link GaugeMetric}, may be null
     */
    public LongGauge(String name, Long initialValue) {
        super(name, initialValue);

    }

    @Override
    public MetricType getType() {
        return MetricType.GAUGE_LONG;
    }

}
