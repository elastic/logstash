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

import com.google.common.annotations.VisibleForTesting;
import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyHash;
import org.jruby.RubyObject;
import org.jruby.RubyString;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.internal.runtime.methods.DynamicMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.instrument.metrics.AbstractNamespacedMetricExt;
import org.logstash.instrument.metrics.timer.NullTimerMetric;
import org.logstash.instrument.metrics.counter.LongCounter;

import java.util.UUID;

import static org.logstash.RubyUtil.RUBY;

@JRubyClass(name = "FilterDelegator")
public final class FilterDelegatorExt extends AbstractFilterDelegatorExt {

    private static final long serialVersionUID = 1L;

    private static final String FILTER_METHOD_NAME = "multi_filter";

    private RubyClass filterClass;

    private transient IRubyObject filter;

    private transient DynamicMethod filterMethod;

    private boolean flushes;

    @JRubyMethod(name="initialize")
    public IRubyObject initialize(final ThreadContext context, final IRubyObject filter, final IRubyObject id) {
        this.id = (RubyString) id;
        this.filter = filter;
        filterClass = filter.getSingletonClass().getRealClass();
        filterMethod = filterClass.searchMethod(FILTER_METHOD_NAME);
        final AbstractNamespacedMetricExt namespacedMetric = (AbstractNamespacedMetricExt) filter.callMethod(context, "metric");
        initMetrics(this.id.asJavaString(), namespacedMetric);
        flushes = filter.respondsTo("flush");
        return this;
    }

    @VisibleForTesting
    public FilterDelegatorExt initForTesting(final IRubyObject filter, RubyObject configNameDouble) {
        eventMetricOut = LongCounter.DUMMY_COUNTER;
        eventMetricIn = LongCounter.DUMMY_COUNTER;
        eventMetricTime = NullTimerMetric.getInstance();
        this.filter = filter;
        filterMethod = filter.getMetaClass().searchMethod(FILTER_METHOD_NAME);
        flushes = filter.respondsTo("flush");
        filterClass = configNameDouble.getType();
        id = RUBY.newString(UUID.randomUUID().toString());
        return this;
    }

    public FilterDelegatorExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @Override
    protected void doRegister(final ThreadContext context) {
        filter.callMethod(context, "register");
    }

    @Override
    protected IRubyObject closeImpl(final ThreadContext context) {
        return filter.callMethod(context, "close");
    }

    @Override
    protected IRubyObject doCloseImpl(final ThreadContext context) {
        return filter.callMethod(context, "do_close");
    }

    @Override
    protected IRubyObject doStopImpl(final ThreadContext context) {
        return filter.callMethod(context, "do_stop");
    }

    @Override
    protected IRubyObject reloadable(final ThreadContext context) {
        return filter.callMethod(context, "reloadable?");
    }

    @Override
    protected IRubyObject isThreadsafe(final ThreadContext context) {
        return filter.callMethod(context, "threadsafe?");
    }

    @Override
    protected IRubyObject getConfigName(final ThreadContext context) {
        return filterClass.callMethod(context, "config_name");
    }

    @Override
    @SuppressWarnings({"rawtypes"})
    protected RubyArray doMultiFilter(final RubyArray batch) {
        final IRubyObject pluginId = this.getId();
        org.apache.logging.log4j.ThreadContext.put("plugin.id", pluginId.toString());
        try {
            return (RubyArray) filterMethod.call(
                    RUBY.getCurrentContext(), filter, filterClass, FILTER_METHOD_NAME, batch);
        } finally {
            org.apache.logging.log4j.ThreadContext.remove("plugin.id");
        }
    }

    @Override
    protected IRubyObject doFlush(final ThreadContext context, final RubyHash options) {
        return filter.callMethod(context, "flush", options);
    }

    @Override
    protected boolean getHasFlush() {
        return flushes;
    }

    @Override
    protected boolean getPeriodicFlush() {
        return filter.callMethod(RUBY.getCurrentContext(), "periodic_flush").isTrue();
    }
}
