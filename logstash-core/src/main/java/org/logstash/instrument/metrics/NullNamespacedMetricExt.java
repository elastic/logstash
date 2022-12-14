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
import org.jruby.RubyObject;
import org.jruby.RubySymbol;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.Block;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;

@JRubyClass(name = "NamespacedNullMetric", parent = "AbstractNamespacedMetric")
public final class NullNamespacedMetricExt extends AbstractNamespacedMetricExt {

    private static final long serialVersionUID = 1L;

    private static final RubySymbol NULL = RubyUtil.RUBY.newSymbol("null");

    private @SuppressWarnings("rawtypes") RubyArray namespaceName;

    private NullMetricExt metric;

    public static AbstractNamespacedMetricExt create(final NullMetricExt metric,
        final @SuppressWarnings("rawtypes") RubyArray namespaceName) {
        final NullNamespacedMetricExt res =
            new NullNamespacedMetricExt(RubyUtil.RUBY, RubyUtil.NULL_NAMESPACED_METRIC_CLASS);
        res.metric = metric;
        res.namespaceName = namespaceName;
        return res;
    }

    public NullNamespacedMetricExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @JRubyMethod(optional = 2)
    public NullNamespacedMetricExt initialize(final ThreadContext context,
        final IRubyObject[] args) {
        this.metric = args.length > 0 && !args[0].isNil() && (args[0] instanceof NullMetricExt) ? (NullMetricExt) args[0] : new NullMetricExt(context.runtime, metaClass);
        final IRubyObject namespaceName = args.length == 2 ? args[1] : NULL;
        if (namespaceName instanceof RubyArray) {
            this.namespaceName = (RubyArray) namespaceName;
        } else {
            this.namespaceName = RubyArray.newArray(context.runtime, namespaceName);
        }
        return this;
    }

    @Override
    protected IRubyObject getCollector(final ThreadContext context) {
        return metric.collector(context);
    }

    @Override
    protected IRubyObject getCounter(final ThreadContext context, final IRubyObject key) {
        return NullNamespacedMetricExt.NullCounter.INSTANCE;
    }

    @Override
    protected IRubyObject getGauge(final ThreadContext context, final IRubyObject key,
        final IRubyObject value) {
        return context.nil;
    }

    @Override
    protected IRubyObject getTimer(ThreadContext context, IRubyObject key) {
        return this.metric.getTimer(context, namespaceName, key);
    }

    @Override
    protected IRubyObject doIncrement(final ThreadContext context, final IRubyObject[] args) {
        return context.nil;
    }

    @Override
    protected IRubyObject doDecrement(final ThreadContext context, final IRubyObject[] args) {
        return context.nil;
    }

    @Override
    protected IRubyObject doTime(final ThreadContext context, final IRubyObject key,
        final Block block) {
        return metric.time(context, namespaceName, key, block);
    }

    @Override
    protected IRubyObject doReportTime(final ThreadContext context, final IRubyObject key,
        final IRubyObject duration) {
        return context.nil;
    }

    @Override
    @SuppressWarnings("rawtypes")
    protected RubyArray getNamespaceName(final ThreadContext context) {
        return namespaceName;
    }

    @Override
    protected AbstractNamespacedMetricExt createNamespaced(final ThreadContext context,
        final IRubyObject name) {
        MetricExt.validateName(context, name, RubyUtil.METRIC_NO_NAMESPACE_PROVIDED_CLASS);
        return create(this.metric, (RubyArray) namespaceName.op_plus(
            name instanceof RubyArray ? name : RubyArray.newArray(context.runtime, name)
        ));
    }

    @Override
    public AbstractMetricExt getMetric() { return this.metric; }

    @JRubyClass(name = "NullCounter")
    public static final class NullCounter extends RubyObject {

        private static final long serialVersionUID = 1L;

        public static final NullNamespacedMetricExt.NullCounter INSTANCE =
            new NullNamespacedMetricExt.NullCounter(RubyUtil.RUBY, RubyUtil.NULL_COUNTER_CLASS);

        public NullCounter(final Ruby runtime, final RubyClass metaClass) {
            super(runtime, metaClass);
        }

        @JRubyMethod
        public IRubyObject increment(final ThreadContext context, final IRubyObject value) {
            return context.nil;
        }
    }
}
