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


package org.logstash.config.ir.compiler;

import java.util.Collection;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyObject;
import org.jruby.RubyString;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.ext.JrubyEventExtLibrary;
import org.logstash.instrument.metrics.AbstractMetricExt;
import org.logstash.instrument.metrics.AbstractNamespacedMetricExt;
import org.logstash.instrument.metrics.MetricKeys;
import org.logstash.instrument.metrics.timer.TimerMetric;
import org.logstash.instrument.metrics.counter.LongCounter;

@JRubyClass(name = "AbstractOutputDelegator")
public abstract class AbstractOutputDelegatorExt extends RubyObject {

    private static final long serialVersionUID = 1L;

    public static final String OUTPUT_METHOD_NAME = "multi_receive";

    private AbstractMetricExt metric;

    protected AbstractNamespacedMetricExt namespacedMetric;

    private AbstractNamespacedMetricExt metricEvents;

    private RubyString id;

    private transient LongCounter eventMetricOut;

    private transient LongCounter eventMetricIn;

    private transient TimerMetric eventMetricTime;

    public AbstractOutputDelegatorExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @JRubyMethod
    public IRubyObject register(final ThreadContext context) {
        doRegister(context);
        return context.nil;
    }

    @JRubyMethod(name = "do_close")
    public IRubyObject doClose(final ThreadContext context) {
        close(context);
        return context.nil;
    }

    @JRubyMethod(name = "reloadable?")
    public IRubyObject isReloadable(final ThreadContext context) {
        return reloadable(context);
    }

    @JRubyMethod
    public IRubyObject concurrency(final ThreadContext context) {
        return getConcurrency(context);
    }

    @JRubyMethod(name = "config_name")
    public IRubyObject configName(final ThreadContext context) {
        return getConfigName(context);
    }

    @JRubyMethod(name = "id")
    public IRubyObject getId() {
        return id;
    }

    @JRubyMethod
    public IRubyObject metric() {
        return metric;
    }

    @JRubyMethod(name = "namespaced_metric")
    public IRubyObject namespacedMetric() {
        return namespacedMetric;
    }

    @JRubyMethod(name = "metric_events")
    public IRubyObject metricEvents() {
        return metricEvents;
    }

    @SuppressWarnings("unchecked")
    @JRubyMethod(name = OUTPUT_METHOD_NAME)
    public IRubyObject multiReceive(final IRubyObject events) {
        @SuppressWarnings("rawtypes")
        final RubyArray batch = (RubyArray) events;
        final int count = batch.size();
        eventMetricIn.increment((long) count);
        eventMetricTime.time(() -> doOutput(batch));
        eventMetricOut.increment((long) count);
        return this;
    }

    protected void initMetrics(final String id, final AbstractMetricExt metric) {
        this.metric = metric;
        final ThreadContext context = RubyUtil.RUBY.getCurrentContext();
        this.id = RubyString.newString(context.runtime, id);
        synchronized (metric) {
            namespacedMetric = metric.namespace(context, context.runtime.newSymbol(id));
            metricEvents = namespacedMetric.namespace(context, MetricKeys.EVENTS_KEY);
            namespacedMetric.gauge(context, MetricKeys.NAME_KEY, configName(context));
            eventMetricOut = LongCounter.fromRubyBase(metricEvents, MetricKeys.OUT_KEY);
            eventMetricIn = LongCounter.fromRubyBase(metricEvents, MetricKeys.IN_KEY);
            eventMetricTime = TimerMetric.fromRubyBase(metricEvents, MetricKeys.DURATION_IN_MILLIS_KEY);
        }
    }

    protected abstract IRubyObject getConfigName(ThreadContext context);

    protected abstract IRubyObject getConcurrency(ThreadContext context);

    protected abstract void doOutput(Collection<JrubyEventExtLibrary.RubyEvent> batch);

    protected abstract void close(ThreadContext context);

    protected abstract void doRegister(ThreadContext context);

    protected abstract IRubyObject reloadable(ThreadContext context);
}
