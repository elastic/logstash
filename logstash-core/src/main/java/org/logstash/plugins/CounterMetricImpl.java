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


package org.logstash.plugins;

import co.elastic.logstash.api.CounterMetric;
import org.jruby.runtime.ThreadContext;
import org.logstash.instrument.metrics.AbstractNamespacedMetricExt;
import org.logstash.instrument.metrics.counter.LongCounter;

/**
 * Default implementation of {@link CounterMetric}
 * */
public class CounterMetricImpl implements CounterMetric {
    private LongCounter longCounter;

    public CounterMetricImpl(final ThreadContext threadContext,
                             final AbstractNamespacedMetricExt metrics,
                             final String metric) {
        this.longCounter = LongCounter.fromRubyBase(metrics, threadContext.getRuntime().newSymbol(metric));
    }

    @Override
    public void increment() {
        this.longCounter.increment();
    }

    @Override
    public void increment(final long delta) {
        this.longCounter.increment(delta);
    }

    @Override
    public long getValue() {
        return this.longCounter.getValue();
    }

    @Override
    public void reset() {
        this.longCounter.reset();
    }
}
