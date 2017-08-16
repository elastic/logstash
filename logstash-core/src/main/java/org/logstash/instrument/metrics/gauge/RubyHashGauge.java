package org.logstash.instrument.metrics.gauge;

import org.jruby.RubyHash;
import org.logstash.instrument.metrics.MetricType;

/**
 * A {@link GaugeMetric} that is backed by a {@link RubyHash}.  Note - This should not be used directly from Java code and exists for passivity with legacy Ruby code. Depending
 * on the types in in the {@link RubyHash} there are no guarantees serializing properly.
 * @deprecated - There are no plans to replace this.
 */
public class RubyHashGauge extends AbstractGaugeMetric<RubyHash> {

    /**
     * Constructor
     *
     * @param name The name of this metric. This value may be used for display purposes.
     * @deprecated - There are no plans to replace this.
     */
    protected RubyHashGauge(String name) {
        super(name);
    }

    /**
     * Constructor - protected so that Ruby may sub class proxy and discourage usage from Java
     *
     * @param name The name of this metric. This value may be used for display purposes.
     * @param initialValue The initial value for this {@link GaugeMetric}, may be null
     * @deprecated - There are no plans to replace this.
     */
    protected RubyHashGauge(String name, RubyHash initialValue) {
        super(name, initialValue);
    }

    @Override
    public MetricType getType() {
        return MetricType.GAUGE_RUBYHASH;
    }

}
