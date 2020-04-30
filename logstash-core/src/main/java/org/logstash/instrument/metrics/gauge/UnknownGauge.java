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
