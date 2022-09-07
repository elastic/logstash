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
import java.util.List;
import java.util.Map;
import java.util.concurrent.Callable;
import java.util.concurrent.TimeUnit;
import java.util.function.Supplier;
import java.util.stream.Collectors;

import co.elastic.logstash.api.TimerMetric;
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
import org.logstash.instrument.metrics.timer.ExecutionMillisTimer;

@JRubyClass(name = "WrappedWriteClient")
public final class JRubyWrappedWriteClientExt extends RubyObject implements QueueWriter {

    private static final long serialVersionUID = 1L;

    public static final RubySymbol PUSH_DURATION_KEY =
        RubyUtil.RUBY.newSymbol("queue_push_duration_in_millis");

    private JRubyAbstractQueueWriteClientExt writeClient;

    private transient LongCounter eventsMetricsCounter;
    private transient TimerMetric eventsMetricsTime;

    private transient LongCounter pipelineMetricsCounter;
    private transient TimerMetric pipelineMetricsTime;

    private transient LongCounter pluginMetricsCounter;
    private transient TimerMetric pluginMetricsTime;

    public JRubyWrappedWriteClientExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @JRubyMethod(required = 4)
    public JRubyWrappedWriteClientExt initialize(final ThreadContext context,
        final IRubyObject[] args) {
        return initialize((JRubyAbstractQueueWriteClientExt) args[0], args[1].asJavaString(),
            (AbstractMetricExt) args[2], args[3]);
    }

    public JRubyWrappedWriteClientExt initialize(
        final JRubyAbstractQueueWriteClientExt queueWriteClientExt, final String pipelineId,
        final AbstractMetricExt metric, final IRubyObject pluginId) {
        this.writeClient = queueWriteClientExt;
        // Synchronize on the metric since setting up new fields on it is not threadsafe
        synchronized (metric) {
            final AbstractNamespacedMetricExt eventsMetrics =
                getMetric(metric, "stats", "events");
            eventsMetricsCounter = LongCounter.fromRubyBase(eventsMetrics, MetricKeys.IN_KEY);
            eventsMetricsTime = ExecutionMillisTimer.fromRubyBase(eventsMetrics, PUSH_DURATION_KEY);
            final AbstractNamespacedMetricExt pipelineMetrics =
                getMetric(metric, "stats", "pipelines", pipelineId, "events");
            pipelineMetricsCounter = LongCounter.fromRubyBase(pipelineMetrics, MetricKeys.IN_KEY);
            pipelineMetricsTime = ExecutionMillisTimer.fromRubyBase(pipelineMetrics, PUSH_DURATION_KEY);
            final AbstractNamespacedMetricExt pluginMetrics = getMetric(
                metric, "stats", "pipelines", pipelineId, "plugins", "inputs",
                pluginId.asJavaString(), "events"
            );
            pluginMetricsCounter =
                LongCounter.fromRubyBase(pluginMetrics, MetricKeys.OUT_KEY);
            pluginMetricsTime = ExecutionMillisTimer.fromRubyBase(pluginMetrics, PUSH_DURATION_KEY);
        }
        return this;
    }

    @JRubyMethod(name = {"push", "<<"}, required = 1)
    public IRubyObject push(final ThreadContext context, final IRubyObject event)
        throws InterruptedException {
        return executeWithTimers(() -> {
            incrementCounters(1L);
            return writeClient.doPush(context, (JrubyEventExtLibrary.RubyEvent) event);
        });
    }

    @SuppressWarnings("unchecked")
    @JRubyMethod(name = "push_batch", required = 1)
    public IRubyObject pushBatch(final ThreadContext context, final IRubyObject batch)
        throws InterruptedException {
        return executeWithTimers(() -> {
            incrementCounters((long) ((Collection<IRubyObject>) batch).size());
            return writeClient.doPushBatch(
                    context, (Collection<JrubyEventExtLibrary.RubyEvent>) batch
            );
        });
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

    @Deprecated
    /**
     * @param start the execution's starting System.nanotime
     * @deprecated use {@link JRubyWrappedWriteClientExt.executeWithTimers}
     */
    private void incrementTimers(final long start) {
        final long increment = TimeUnit.MILLISECONDS.convert(
            System.nanoTime() - start, TimeUnit.NANOSECONDS
        );
        eventsMetricsTime.reportUntracked(increment);
        pipelineMetricsTime.reportUntracked(increment);
        pluginMetricsTime.reportUntracked(increment);
    }

    private <V,E extends Exception> V executeWithTimers(final ExceptionalSupplier<V,E> supplier) throws E {
        final List<TimerMetric> timers = List.of(eventsMetricsTime, pipelineMetricsTime, pluginMetricsTime);
        final List<TimerMetric.Committer> committers = timers.stream().map(TimerMetric::begin).collect(Collectors.toList());
        try {
            return supplier.get();
        } finally {
            committers.forEach(TimerMetric.Committer::commit);
        }
    }

    @FunctionalInterface
    private interface ExceptionalSupplier<V,E extends Exception> {
        V get() throws E;
    }

    private static AbstractNamespacedMetricExt getMetric(final AbstractMetricExt base,
        final String... keys) {
        return base.namespace(RubyUtil.RUBY.getCurrentContext(), toSymbolArray(keys));
    }

    private static IRubyObject toSymbolArray(final String... strings) {
        final IRubyObject[] res = new IRubyObject[strings.length];
        for (int i = 0; i < strings.length; ++i) {
            res[i] = RubyUtil.RUBY.newSymbol(strings[i]);
        }
        return RubyUtil.RUBY.newArray(res);
    }

    @Override
    public void push(Map<String, Object> event) {
        executeWithTimers(() -> {
            incrementCounters(1L);
            writeClient.push(event);
            return null;
        });
    }
}
