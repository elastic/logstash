package org.logstash.instrument.metrics.gauge;

import org.logstash.Timestamp;
import org.logstash.bivalues.BiValues;
import org.logstash.ext.JrubyTimestampExtLibrary.RubyTimestamp;
import org.logstash.instrument.metrics.AbstractMetric;
import org.logstash.instrument.metrics.MetricType;

import java.util.List;

/**
 * A {@link GaugeMetric} that is set by a {@link RubyTimestamp}, and retrieved/serialized as a {@link Timestamp}.  Note - This should not be used directly from Java code and
 * exists for passivity with legacy Ruby code.
 */
public class RubyTimeStampGauge extends AbstractMetric<Timestamp> implements GaugeMetric<Timestamp, RubyTimestamp> {

    private volatile Timestamp value;

    /**
     * Constructor - protected so that Ruby may sub class proxy and discourage usage from Java, null initial value
     *
     * @param nameSpace The namespace for this metric
     * @param key       The key <i>(with in the namespace)</i> for this metric
     */
    protected RubyTimeStampGauge(List<String> nameSpace, String key) {
        this(nameSpace, key, null);
    }

    /**
     * Constructor - protected so that Ruby may sub class proxy and discourage usage from Java
     *
     * @param nameSpace    The namespace for this metric
     * @param key          The key <i>(with in the namespace)</i> for this metric
     * @param initialValue The initial value for this {@link GaugeMetric}, may be null
     */
    protected RubyTimeStampGauge(List<String> nameSpace, String key, RubyTimestamp initialValue) {
        super(nameSpace, key);
        this.value = initialValue == null ? null : initialValue.getTimestamp();
    }

    @Override
    public MetricType getType() {
        return MetricType.GAUGE_RUBYTIMESTAMP;
    }

    @Override
    public Timestamp getValue() {
        return value;
    }

    @Override
    public void set(RubyTimestamp value) {
        this.value = value == null ? null : value.getTimestamp();
    }
}