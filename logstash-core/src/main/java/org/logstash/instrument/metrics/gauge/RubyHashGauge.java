package org.logstash.instrument.metrics.gauge;

import org.jruby.RubyHash;
import org.logstash.instrument.metrics.AbstractMetric;
import org.logstash.instrument.metrics.MetricType;


import java.util.List;

/**
 * A {@link GaugeMetric} that is backed by a {@link RubyHash}.  Note - This should not be used directly from Java code and exists for passivity with legacy Ruby code. Depending
 * on the types in in the {@link RubyHash} there are no guarantees serializing properly.
 */
public class RubyHashGauge extends AbstractMetric<RubyHash> implements GaugeMetric<RubyHash,RubyHash> {

    private volatile RubyHash value;

    /**
     * Constructor - protected so that Ruby may sub class proxy and discourage usage from Java, null initial value
     *
     * @param nameSpace    The namespace for this metric
     * @param key          The key <i>(with in the namespace)</i> for this metric
     */
    protected RubyHashGauge(List<String> nameSpace, String key) {
        this(nameSpace, key, null);
    }

    /**
     * Constructor - protected so that Ruby may sub class proxy and discourage usage from Java
     *
     * @param nameSpace    The namespace for this metric
     * @param key          The key <i>(with in the namespace)</i> for this metric
     * @param initialValue The initial value for this {@link GaugeMetric}, may be null
     */
    protected RubyHashGauge(List<String> nameSpace, String key, RubyHash initialValue) {
        super(nameSpace, key);
        this.value = initialValue;
    }

    @Override
    public MetricType getType() {
        return MetricType.GAUGE_RUBYHASH;
    }

    @Override
    public RubyHash getValue() {
        return value;
    }

    @Override
    public void set(RubyHash value) {
        this.value = value;
    }

}
