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

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyHash;
import org.jruby.RubyObject;
import org.jruby.RubyString;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.ext.JrubyEventExtLibrary;
import org.logstash.instrument.metrics.AbstractNamespacedMetricExt;
import org.logstash.instrument.metrics.MetricKeys;
import org.logstash.instrument.metrics.timer.TimerMetric;
import org.logstash.instrument.metrics.counter.LongCounter;

import java.util.Collection;

@JRubyClass(name = "AbstractFilterDelegator")
public abstract class AbstractFilterDelegatorExt extends RubyObject {

    private static final long serialVersionUID = 1L;

    protected AbstractNamespacedMetricExt metricEvents;

    protected RubyString id;

    protected transient LongCounter eventMetricOut;

    protected transient LongCounter eventMetricIn;

    protected transient TimerMetric eventMetricTime;

    public AbstractFilterDelegatorExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    protected void initMetrics(final String id, final AbstractNamespacedMetricExt namespacedMetric) {
        final ThreadContext context = RubyUtil.RUBY.getCurrentContext();
        this.id = RubyString.newString(context.runtime, id);
        synchronized(namespacedMetric.getMetric()) {
            metricEvents = namespacedMetric.namespace(context, MetricKeys.EVENTS_KEY);
            eventMetricOut = LongCounter.fromRubyBase(metricEvents, MetricKeys.OUT_KEY);
            eventMetricIn = LongCounter.fromRubyBase(metricEvents, MetricKeys.IN_KEY);
            eventMetricTime = TimerMetric.fromRubyBase(metricEvents, MetricKeys.DURATION_IN_MILLIS_KEY);
            namespacedMetric.gauge(context, MetricKeys.NAME_KEY, configName(context));
        }
    }

    @JRubyMethod
    public IRubyObject register(final ThreadContext context) {
        doRegister(context);
        return context.nil;
    }

    protected abstract void doRegister(final ThreadContext context);

    @JRubyMethod
    public IRubyObject close(final ThreadContext context) {
        return closeImpl(context);
    }

    protected abstract IRubyObject closeImpl(final ThreadContext context);

    @JRubyMethod(name = "do_close")
    public IRubyObject doClose(final ThreadContext context) {
        return doCloseImpl(context);
    }

    protected abstract IRubyObject doCloseImpl(final ThreadContext context);

    @JRubyMethod(name = "do_stop")
    public IRubyObject doStop(final ThreadContext context) {
        return doStopImpl(context);
    }

    protected abstract IRubyObject doStopImpl(final ThreadContext context);

    @JRubyMethod(name = "reloadable?")
    public IRubyObject isReloadable(final ThreadContext context) {
        return reloadable(context);
    }

    protected abstract IRubyObject reloadable(final ThreadContext context);

    @JRubyMethod(name = "threadsafe?")
    public IRubyObject threadsafe(final ThreadContext context) {
        return isThreadsafe(context);
    }

    protected abstract IRubyObject isThreadsafe(final ThreadContext context);

    @JRubyMethod(name = "config_name")
    public IRubyObject configName(final ThreadContext context) {
        return getConfigName(context);
    }

    protected abstract IRubyObject getConfigName(ThreadContext context);

    @JRubyMethod(name = "id")
    public IRubyObject getId() {
        return id;
    }

    @JRubyMethod(name = "multi_filter")
    @SuppressWarnings({"unchecked", "rawtypes"})
    public RubyArray multiFilter(final IRubyObject input) {
        RubyArray batch = (RubyArray) input;
        eventMetricIn.increment((long) batch.size());
        final RubyArray result = eventMetricTime.time(() -> doMultiFilter(batch));
        int count = 0;
        for (final JrubyEventExtLibrary.RubyEvent event : (Collection<JrubyEventExtLibrary.RubyEvent>) result) {
            if (!event.getEvent().isCancelled()) {
                ++count;
            }
        }
        eventMetricOut.increment((long) count);
        return result;
    }

    @SuppressWarnings({"rawtypes"})
    protected abstract RubyArray doMultiFilter(final RubyArray batch);

    @JRubyMethod(name = "flush")
    @SuppressWarnings("rawtypes")
    public RubyArray flush(final IRubyObject input) {
        RubyHash options = (RubyHash) input;
        final ThreadContext context = RubyUtil.RUBY.getCurrentContext();
        final IRubyObject newEvents = doFlush(context, options);
        final RubyArray result;
        if (newEvents.isNil()) {
            result = RubyArray.newEmptyArray(context.runtime);
        } else {
            result = (RubyArray) newEvents;
            eventMetricOut.increment((long) result.size());
        }
        return result;
    }

    @JRubyMethod(name = "has_flush")
    public IRubyObject hasFlush(ThreadContext context) {
        return hasFlush() ? context.tru : context.fals;
    }

    @JRubyMethod(name = "periodic_flush")
    public IRubyObject hasPeriodicFlush(ThreadContext context) {
        return periodicFlush() ? context.tru : context.fals;
    }

    protected abstract IRubyObject doFlush(final ThreadContext context, final RubyHash options);

    public boolean hasFlush() {
        return getHasFlush();
    }

    protected abstract boolean getHasFlush();

    public boolean periodicFlush() {
        return getPeriodicFlush();
    }

    protected abstract boolean getPeriodicFlush();
}
