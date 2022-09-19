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


package org.logstash.ext;

import java.util.Collection;
import java.util.Map;
import java.util.concurrent.TimeUnit;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyObject;
import org.jruby.RubySymbol;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.execution.queue.QueueWriter;
import org.logstash.instrument.metrics.AbstractMetricExt;
import org.logstash.instrument.metrics.AbstractNamespacedMetricExt;
import org.logstash.instrument.metrics.MetricKeys;
import org.logstash.instrument.metrics.counter.LongCounter;

import static org.logstash.instrument.metrics.MetricKeys.*;

@JRubyClass(name = "WrappedWriteClient")
public final class JRubyWrappedWriteClientExt extends RubyObject implements QueueWriter {

    private static final long serialVersionUID = 1L;

    private JRubyAbstractQueueWriteClientExt writeClient;

    private transient LongCounter eventsMetricsCounter;

    private transient LongCounter eventsMetricsTime;

    private transient LongCounter pipelineMetricsCounter;

    private transient LongCounter pipelineMetricsTime;

    private transient LongCounter pluginMetricsCounter;

    private transient LongCounter pluginMetricsTime;

    public JRubyWrappedWriteClientExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @JRubyMethod(required = 4)
    public JRubyWrappedWriteClientExt initialize(final ThreadContext context,
        final IRubyObject[] args) {
        return initialize((JRubyAbstractQueueWriteClientExt) args[0], args[1].asJavaString(),
            (AbstractMetricExt) args[2], args[3]);
    }

    public JRubyWrappedWriteClientExt initialize(final JRubyAbstractQueueWriteClientExt queueWriteClientExt,
                                                 final String pipelineId,
                                                 final AbstractMetricExt metric,
                                                 final IRubyObject pluginId) {
        this.writeClient = queueWriteClientExt;

        final RubySymbol pipelineIdSym = getRuntime().newSymbol(pipelineId);
        final RubySymbol pluginIdSym = pluginId.asString().intern();

        // Synchronize on the metric since setting up new fields on it is not threadsafe
        synchronized (metric) {
            final AbstractNamespacedMetricExt eventsMetrics =
                getMetric(metric, STATS_KEY, EVENTS_KEY);

            eventsMetricsCounter = LongCounter.fromRubyBase(eventsMetrics, MetricKeys.IN_KEY);
            eventsMetricsTime = LongCounter.fromRubyBase(eventsMetrics, MetricKeys.PUSH_DURATION_KEY);

            final AbstractNamespacedMetricExt pipelineEventMetrics =
                getMetric(metric, STATS_KEY, PIPELINES_KEY, pipelineIdSym, EVENTS_KEY);

            pipelineMetricsCounter = LongCounter.fromRubyBase(pipelineEventMetrics, MetricKeys.IN_KEY);
            pipelineMetricsTime = LongCounter.fromRubyBase(pipelineEventMetrics, MetricKeys.PUSH_DURATION_KEY);

            final AbstractNamespacedMetricExt pluginMetrics =
                    getMetric(metric, STATS_KEY, PIPELINES_KEY, pipelineIdSym, PLUGINS_KEY, INPUTS_KEY, pluginIdSym, EVENTS_KEY);
            pluginMetricsCounter =
                LongCounter.fromRubyBase(pluginMetrics, MetricKeys.OUT_KEY);
            pluginMetricsTime = LongCounter.fromRubyBase(pluginMetrics, MetricKeys.PUSH_DURATION_KEY);
        }

        return this;
    }

    @JRubyMethod(name = {"push", "<<"}, required = 1)
    public IRubyObject push(final ThreadContext context, final IRubyObject event)
        throws InterruptedException {
        final long start = System.nanoTime();
        incrementCounters(1L);
        final IRubyObject res = writeClient.doPush(context, (JrubyEventExtLibrary.RubyEvent) event);
        incrementTimers(start);
        return res;
    }

    @SuppressWarnings("unchecked")
    @JRubyMethod(name = "push_batch", required = 1)
    public IRubyObject pushBatch(final ThreadContext context, final IRubyObject batch)
        throws InterruptedException {
        final long start = System.nanoTime();
        incrementCounters((long) ((Collection<IRubyObject>) batch).size());
        final IRubyObject res = writeClient.doPushBatch(
            context, (Collection<JrubyEventExtLibrary.RubyEvent>) batch
        );
        incrementTimers(start);
        return res;
    }

    /**
     * @param context Ruby {@link ThreadContext}
     * @return Empty {@link RubyArray}
     * @deprecated This method exists for backwards compatibility only, it does not do anything but
     * return an empty {@link RubyArray}.
     */
    @Deprecated
    @JRubyMethod(name = "get_new_batch")
    public IRubyObject newBatch(final ThreadContext context) {
        return context.runtime.newArray();
    }

    private void incrementCounters(final long count) {
        eventsMetricsCounter.increment(count);
        pipelineMetricsCounter.increment(count);
        pluginMetricsCounter.increment(count);
    }

    private void incrementTimers(final long start) {
        final long increment = TimeUnit.MILLISECONDS.convert(
            System.nanoTime() - start, TimeUnit.NANOSECONDS
        );
        eventsMetricsTime.increment(increment);
        pipelineMetricsTime.increment(increment);
        pluginMetricsTime.increment(increment);
    }


    private AbstractNamespacedMetricExt getMetric(final AbstractMetricExt base,
                                                  final RubySymbol... keys) {
        return base.namespace(getRuntime().getCurrentContext(), getRuntime().newArray(keys));
    }

    @Override
    public void push(Map<String, Object> event) {
        final long start = System.nanoTime();
        incrementCounters(1L);
        writeClient.push(event);
        incrementTimers(start);
    }
}
