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

import co.elastic.logstash.api.Metric;
import co.elastic.logstash.api.NamespacedMetric;
import org.jruby.RubyArray;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.instrument.metrics.AbstractMetricExt;

import java.util.stream.Stream;

/**
 * Wraps a {@link AbstractMetricExt} and represents a "root metric" that must be
 * namespaced in order to write metrics to.
 */
public class RootMetricImpl implements Metric {
    private final ThreadContext threadContext;
    private final AbstractMetricExt metrics;

    public RootMetricImpl(final ThreadContext threadContext, final AbstractMetricExt root) {
        this.threadContext = threadContext;
        this.metrics = root;
    }

    @Override
    public NamespacedMetric namespace(final String... key) {
        final IRubyObject[] rubyfiedKeys = Stream.of(key)
            .map(this.threadContext.getRuntime()::newSymbol)
            .toArray(IRubyObject[]::new);

        return new NamespacedMetricImpl(
            this.threadContext,
            this.metrics.namespace(this.threadContext, RubyArray.newArray(this.threadContext.getRuntime(), rubyfiedKeys))
        );
    }
}
