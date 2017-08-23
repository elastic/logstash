package org.logstash.instrument.metrics.gauge;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.jruby.RubyHash;
import org.logstash.ext.JrubyTimestampExtLibrary.RubyTimestamp;
import org.logstash.instrument.metrics.AbstractMetric;
import org.logstash.instrument.metrics.MetricType;

/**
 * A lazy proxy to a more specific typed {@link GaugeMetric}. The metric will only be initialized if the initial value is set, or once the {@code set} operation is called.
 * <p><strong>Intended only for use with Ruby's duck typing, Java consumers should use the specific typed {@link GaugeMetric}</strong></p>
 *
 * @deprecated - there are no plans to replace this.
 */
public class LazyDelegatingGauge extends AbstractMetric<Object> implements GaugeMetric<Object, Object> {

    private final static Logger LOGGER = LogManager.getLogger(LazyDelegatingGauge.class);

    protected final String key;

    private GaugeMetric lazyMetric;

    /**
     * Constructor - null initial value
     *
     * @param key The key <i>(with in the namespace)</i> for this metric
     * @deprecated - there are no plans to replace this
     */
    public LazyDelegatingGauge(final String key) {
        this(key, null);
    }

    /**
     * Constructor - with initial value
     *
     * @param key          The key for this metric
     * @param initialValue The initial value for this {@link GaugeMetric}, may be null
     * @deprecated - there are no plans to replace this
     */
    public LazyDelegatingGauge(String key, Object initialValue) {
        super(key);
        this.key = key;
        if (initialValue != null) {
            wakeMetric(initialValue);
        }
    }

    @Override
    @SuppressWarnings("deprecation")
    public Object get() {
        return lazyMetric == null ? null : lazyMetric.get();
    }

    @Override
    public MetricType getType() {
        return lazyMetric == null ? null : lazyMetric.getType();
    }

    @Override
    public Object getValue() {
        return lazyMetric == null ? null : lazyMetric.getValue();
    }

    @Override
    public void set(Object value) {
        if (lazyMetric == null) {
            wakeMetric(value);
        } else {
            lazyMetric.set(value);
        }
    }

    /**
     * Instantiates the metric based on the type used to set this Gauge
     *
     * @param value The object used to set this value
     */
    private synchronized void wakeMetric(Object value) {
        if (lazyMetric == null && value != null) {
            //"quack quack"
            if (value instanceof String) {
                lazyMetric = new TextGauge(key, (String) value);
            } else if (value instanceof Number) {
                lazyMetric = new NumberGauge(key, (Number) value);
            } else if (value instanceof Boolean) {
                lazyMetric = new BooleanGauge(key, (Boolean) value);
            } else if (value instanceof RubyHash) {
                lazyMetric = new RubyHashGauge(key, (RubyHash) value);
            } else if (value instanceof RubyTimestamp) {
                lazyMetric = new RubyTimeStampGauge(key, ((RubyTimestamp) value));
            } else {
                LOGGER.warn("A gauge metric of an unknown type ({}) has been create for key: {}. This may result in invalid serialization.  It is recommended to " +
                        "log an issue to the responsible developer/development team.", value.getClass().getCanonicalName(), key);
                lazyMetric = new UnknownGauge(key, value);
            }
        }
     }
}
