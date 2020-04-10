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

import org.logstash.Timestamp;
import org.logstash.ext.JrubyTimestampExtLibrary.RubyTimestamp;
import org.logstash.instrument.metrics.AbstractMetric;
import org.logstash.instrument.metrics.MetricType;

/**
 * A {@link GaugeMetric} that is set by a {@link RubyTimestamp}, and retrieved/serialized as a {@link Timestamp}.  Note - This should not be used directly from Java code and
 * exists for passivity with legacy Ruby code.
 * @deprecated - There are no plans to replace this.
 */
@Deprecated
public class RubyTimeStampGauge extends AbstractMetric<Timestamp> implements GaugeMetric<Timestamp, RubyTimestamp> {

    private volatile Timestamp value;

    /**
     * Constructor
     *
     * @param key       The key <i>(with in the namespace)</i> for this metric
     * @deprecated - There are no plans to replace this.
     */
    @Deprecated
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
    @Deprecated
    protected RubyTimeStampGauge(String key, RubyTimestamp initialValue) {
        super(key);
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
