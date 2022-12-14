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


package org.logstash.instrument.metrics;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyFixnum;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.Block;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.instrument.metrics.timer.NullTimerMetric;

@JRubyClass(name = "NullMetric")
public final class NullMetricExt extends AbstractSimpleMetricExt {

    private static final long serialVersionUID = 1L;

    private static final IRubyObject NULL_TIMER_METRIC = RubyUtil.toRubyObject(NullTimerMetric.getInstance());

    private transient IRubyObject collector;

    public static NullMetricExt create() {
        return new NullMetricExt(
            RubyUtil.RUBY, RubyUtil.NULL_METRIC_CLASS
        ).initialize(RubyUtil.RUBY.getCurrentContext(), new IRubyObject[0]);
    }

    public NullMetricExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @JRubyMethod(optional = 1)
    public NullMetricExt initialize(final ThreadContext context, final IRubyObject[] collector) {
        if (collector.length == 0) {
            this.collector = context.nil;
        } else {
            this.collector = collector[0];
        }
        return this;
    }

    @Override
    protected IRubyObject getCollector(final ThreadContext context) {
        return collector;
    }

    @Override
    protected IRubyObject doIncrement(final ThreadContext context, final IRubyObject[] args) {
        MetricExt.validateKey(context, null, args[1]);
        return context.nil;
    }

    @Override
    protected IRubyObject doDecrement(final ThreadContext context, final IRubyObject[] args) {
        MetricExt.validateKey(context, null, args[1]);
        return context.nil;
    }

    @Override
    protected IRubyObject getGauge(final ThreadContext context, final IRubyObject namespace,
        final IRubyObject key, final IRubyObject value) {
        MetricExt.validateKey(context, null, key);
        return context.nil;
    }

    @Override
    protected IRubyObject getTimer(final ThreadContext context,
                                   final IRubyObject namespace,
                                   final IRubyObject key) {
        MetricExt.validateKey(context, null, key);
        return NULL_TIMER_METRIC;
    }

    @Override
    protected IRubyObject doReportTime(final ThreadContext context, final IRubyObject namespace,
        final IRubyObject key, final IRubyObject duration) {
        MetricExt.validateKey(context, null, key);
        return context.nil;
    }

    @Override
    protected IRubyObject doTime(final ThreadContext context, final IRubyObject namespace,
        final IRubyObject key, final Block block) {
        MetricExt.validateKey(context, null, key);
        if (!block.isGiven()) {
            return NullMetricExt.NullTimedExecution.INSTANCE;
        }
        return block.call(context);
    }

    @Override
    protected AbstractNamespacedMetricExt createNamespaced(final ThreadContext context,
        final IRubyObject name) {
        MetricExt.validateName(context, name, RubyUtil.METRIC_NO_NAMESPACE_PROVIDED_CLASS);
        return NullNamespacedMetricExt.create(
            this,
            name instanceof RubyArray ? (RubyArray) name : RubyArray.newArray(context.runtime, name)
        );
    }

    @JRubyClass(name = "NullTimedExecution")
    public static final class NullTimedExecution extends RubyObject {

        private static final long serialVersionUID = 1L;

        private static final NullMetricExt.NullTimedExecution INSTANCE =
            new NullMetricExt.NullTimedExecution(RubyUtil.RUBY, RubyUtil.NULL_TIMED_EXECUTION_CLASS);

        public NullTimedExecution(final Ruby runtime, final RubyClass metaClass) {
            super(runtime, metaClass);
        }

        @JRubyMethod
        public RubyFixnum stop(final ThreadContext context) {
            return RubyFixnum.newFixnum(context.runtime, 0L);
        }
    }
}
