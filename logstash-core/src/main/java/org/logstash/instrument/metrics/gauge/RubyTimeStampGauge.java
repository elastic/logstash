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
 * @deprecated - There are no plans to replace this.
 */
public class RubyTimeStampGauge extends AbstractMetric<Timestamp> implements GaugeMetric<Timestamp, RubyTimestamp> {

    private volatile Timestamp value;

    private volatile boolean dirty;

    /**
     * Constructor
     *
     * @param key       The key <i>(with in the namespace)</i> for this metric
     * @deprecated - There are no plans to replace this.
     */
    public RubyTimeStampGauge(String key) {
        super(key);
    }

    /**
     * Constructor - protected so that Ruby may sub class proxy and discourage usage from Java
     *
     * @param key          The key <i>(with in the namespace)</i> for this metric
     * @param initialValue The initial value for this {@link GaugeMetric}, may be null
     * @deprecated - There are no plans to replace this.
     */
    protected RubyTimeStampGauge(String key, RubyTimestamp initialValue) {
        super(key);
        this.value = initialValue == null ? null : initialValue.getTimestamp();
        setDirty(true);
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
    public boolean isDirty() {
        return dirty;
    }

    @Override
    public void setDirty(boolean dirty) {
        this.dirty = dirty;
    }

    @Override
    public void set(RubyTimestamp value) {
        this.value = value == null ? null : value.getTimestamp();
        setDirty(true);
    }
}