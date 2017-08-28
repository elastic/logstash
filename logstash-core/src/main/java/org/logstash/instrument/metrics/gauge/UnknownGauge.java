package org.logstash.instrument.metrics.gauge;

import org.logstash.instrument.metrics.MetricType;

/**
 * A {@link GaugeMetric} that is backed by a {@link Object}.  Note - A stronger typed {@link GaugeMetric} should be used since this makes no guarantees of serializing properly.
 * @deprecated - There are no plans to replace this.
 */
@Deprecated
public class UnknownGauge extends AbstractGaugeMetric<Object> {

    /**
     * Constructor
     *
     * @param name The name of this metric. This value may be used for display purposes.
     * @deprecated - There are no plans to replace this.
     */
    @Deprecated
    public UnknownGauge(String name) {
        super(name);
    }

    /**
     * Constructor
     *
     * @param name         The name of this metric. This value may be used for display purposes.
     * @param initialValue The initial value for this {@link GaugeMetric}, may be null
     * @deprecated - There are no plans to replace this.
     */
    @Deprecated
    public UnknownGauge(String name, Object initialValue) {
        super(name, initialValue);
    }

    @Override
    public MetricType getType() {
        return MetricType.GAUGE_UNKNOWN;
    }
}
