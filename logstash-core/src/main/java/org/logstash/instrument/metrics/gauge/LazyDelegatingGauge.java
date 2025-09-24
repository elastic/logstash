/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *	http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */


package org.logstash.instrument.metrics.gauge;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.jruby.RubyHash;
import org.jruby.RubySymbol;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.ext.JrubyTimestampExtLibrary.RubyTimestamp;
import org.logstash.instrument.metrics.AbstractMetric;
import org.logstash.instrument.metrics.AbstractNamespacedMetricExt;
import org.logstash.instrument.metrics.MetricType;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;

/**
 * A lazy proxy to a more specific typed {@link GaugeMetric}. The metric will only be initialized if the initial value is set, or once the {@code set} operation is called.
 * <p><strong>Intended only for use with Ruby's duck typing, Java consumers should use the specific typed {@link GaugeMetric}</strong></p>
 *
 */
public class LazyDelegatingGauge extends AbstractMetric<Object> implements GaugeMetric<Object, Object> {

    private static final Logger LOGGER = LogManager.getLogger(LazyDelegatingGauge.class);

    public static final LazyDelegatingGauge DUMMY_GAUGE = new LazyDelegatingGauge("dummy");

    protected final String key;

    @SuppressWarnings("rawtypes")
    private GaugeMetric lazyMetric;


    public static LazyDelegatingGauge fromRubyBase(final AbstractNamespacedMetricExt metric, final RubySymbol key) {
        final ThreadContext context = RubyUtil.RUBY.getCurrentContext();
        // just initialize an empty gauge
        final IRubyObject gauge = metric.gauge(context, key, context.runtime.newArray(context.runtime.newString("undefined"), context.runtime.newString("undefined")));
        final LazyDelegatingGauge javaGauge;
        if (LazyDelegatingGauge.class.isAssignableFrom(gauge.getJavaClass())) {
            javaGauge = gauge.toJava(LazyDelegatingGauge.class);
        } else {
            javaGauge = DUMMY_GAUGE;
        }
        return javaGauge;
    }

    /**
     * Constructor - null initial value
     *
     * @param key The key <i>(with in the namespace)</i> for this metric
     */
    
    public LazyDelegatingGauge(final String key) {
        this(key, null);
    }

    /**
     * Constructor - with initial value
     *
     * @param key          The key for this metric
     * @param initialValue The initial value for this {@link GaugeMetric}, may be null
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

    @SuppressWarnings("rawtypes")
    public Optional getMetric() {
        return Optional.ofNullable(lazyMetric);
    }

    @Override
    public MetricType getType() {
        return lazyMetric == null ? null : lazyMetric.getType();
    }

    @Override
    public Object getValue() {
        return lazyMetric == null ? null : lazyMetric.getValue();
    }

    @SuppressWarnings("unchecked")
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
    @SuppressWarnings("deprecation")
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
                lazyMetric = new RubyTimeStampGauge(key, (RubyTimestamp) value);
            } else if (value instanceof List<?>) {
                lazyMetric = new ListGauge(key, (List<?>) value);
            } else {
                LOGGER.warn("A gauge metric of an unknown type ({}) has been created for key: {}. This may result in invalid serialization.  It is recommended to " +
                        "log an issue to the responsible developer/development team.", value.getClass().getCanonicalName(), key);
                lazyMetric = new UnknownGauge(key, value);
            }
        }
     }
}
