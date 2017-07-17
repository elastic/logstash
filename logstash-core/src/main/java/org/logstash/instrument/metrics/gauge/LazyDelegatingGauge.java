package org.logstash.instrument.metrics.gauge;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.jruby.RubyHash;
import org.logstash.Timestamp;
import org.logstash.ext.JrubyTimestampExtLibrary.RubyTimestamp;
import org.logstash.instrument.metrics.AbstractMetric;
import org.logstash.instrument.metrics.MetricType;

import java.util.List;

/**
 * A lazy proxy to a more specific typed {@link GaugeMetric}. The metric will only be initialized if the initial value is set, or once the {@code set} operation is called.
 * <p><strong>Intended only for use with Ruby's duck typing, Java consumers should use the specific typed {@link GaugeMetric}</strong></p>
 */
public class LazyDelegatingGauge extends AbstractMetric<Object> implements GaugeMetric<Object,Object> {

    private final static Logger LOGGER = LogManager.getLogger(LazyDelegatingGauge.class);

    protected final String key;
    protected final List<String> nameSpaces;

    private GaugeMetric lazyMetric;

    /**
     * Constructor - protected so that Ruby may sub class proxy and discourage usage from Java, null initial value
     *
     * @param nameSpace The namespace for this metric
     * @param key       The key <i>(with in the namespace)</i> for this metric
     */
    public LazyDelegatingGauge(final List<String> nameSpace, final String key) {
        this(nameSpace, key, null);
    }

    /**
     * Constructor - protected so that Ruby may sub class proxy and discourage usage from Java
     *
     * @param nameSpace    The namespace for this metric
     * @param key          The key <i>(with in the namespace)</i> for this metric
     * @param initialValue The initial value for this {@link GaugeMetric}, may be null
     */
    protected LazyDelegatingGauge(List<String> nameSpace, String key, Object initialValue) {
        super(nameSpace, key);
        this.nameSpaces = nameSpace;
        this.key = key;
        if (initialValue != null) {
            wakeMetric(initialValue);
        }
    }

    @Override
    @SuppressWarnings( "deprecation" )
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
            if (value instanceof Number) {
                lazyMetric = new NumericGauge(nameSpaces, key, (Number) value);
            } else if (value instanceof String) {
                lazyMetric = new TextGauge(nameSpaces, key, (String) value);
            } else if (value instanceof Boolean) {
                lazyMetric = new BooleanGauge(nameSpaces, key, (Boolean) value);
            } else if (value instanceof RubyHash) {
                lazyMetric = new RubyHashGauge(nameSpaces, key, (RubyHash) value);
            } else if (value instanceof RubyTimestamp) {
                lazyMetric = new RubyTimeStampGauge(nameSpaces, key, ((RubyTimestamp) value));
            } else {
                LOGGER.warn("A gauge metric of an unknown type ({}) has been create for key: {}, namespace:{}. This may result in invalid serialization.  It is recommended to " +
                        "log an issue to the responsible developer/development team.", value.getClass().getCanonicalName(), key, nameSpaces);
                lazyMetric = new UnknownGauge(nameSpaces, key, value);
            }
        }
    }

}
