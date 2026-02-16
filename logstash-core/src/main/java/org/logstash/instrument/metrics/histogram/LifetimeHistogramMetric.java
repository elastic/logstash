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

package org.logstash.instrument.metrics.histogram;

import co.elastic.logstash.api.UserMetric;
import org.logstash.instrument.metrics.AbstractMetric;
import org.HdrHistogram.Histogram;
import org.HdrHistogram.Recorder;

import java.util.Objects;

public class LifetimeHistogramMetric extends AbstractMetric<Histogram> implements HistogramMetric {

    private final Recorder recorder;
    private volatile Histogram lifetimeSnapshot;

    public static UserMetric.Factory<HistogramMetric> FACTORY =
            HistogramMetric.PROVIDER.getFactory(LifetimeHistogramMetric::new);

    public LifetimeHistogramMetric(String name) {
        super(name);
        //TODO recorder should be provided as a parameter constructor or lazy-initialized by a supplier, but this is sufficient for now
        this.recorder = new Recorder(3);
        this.lifetimeSnapshot = recorder.getIntervalHistogram();
    }

    @Override
    public void recordValue(long value) {
        if (value < 0) {
            throw new IllegalArgumentException("cannot record negative value in histogram");
        }
        recorder.recordValue(value);
    }

    @Override
    public Histogram getValue() {
        // TODO use an AtomicReference for lifetimeSnapshot
        Histogram uncommitted = recorder.getIntervalHistogram();
        lifetimeSnapshot = copyAdding(lifetimeSnapshot, uncommitted);
        return lifetimeSnapshot;
    }

    private Histogram copyAdding(Histogram lifetime, Histogram other) {
        if (Objects.isNull(other) || other.getTotalCount()  == 0) {
            return lifetime;
        }

        final Histogram result = lifetime.copy();
        result.add(other);

        return result;
    }
}
