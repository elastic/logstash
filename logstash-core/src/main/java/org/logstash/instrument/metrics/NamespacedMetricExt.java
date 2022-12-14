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
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.Block;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.Visibility;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;

@JRubyClass(name = "NamespacedMetric")
public final class NamespacedMetricExt extends AbstractNamespacedMetricExt {

    private static final long serialVersionUID = 1L;

    private @SuppressWarnings("rawtypes") RubyArray namespaceName;

    private MetricExt metric;

    public static NamespacedMetricExt create(final MetricExt metric,
        final @SuppressWarnings("rawtypes") RubyArray namespaceName) {
        final NamespacedMetricExt res =
            new NamespacedMetricExt(RubyUtil.RUBY, RubyUtil.NAMESPACED_METRIC_CLASS);
        res.metric = metric;
        res.namespaceName = namespaceName;
        return res;
    }

    public NamespacedMetricExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @JRubyMethod(visibility = Visibility.PRIVATE)
    public NamespacedMetricExt initialize(final ThreadContext context, final IRubyObject metric,
        final IRubyObject namespaceName) {
        this.metric = (MetricExt) metric;
        this.namespaceName = normalizeNamespace(namespaceName);
        return this;
    }

    @Override
    protected IRubyObject getCollector(final ThreadContext context) {
        return metric.collector(context);
    }

    @Override
    protected IRubyObject getCounter(final ThreadContext context, final IRubyObject key) {
        return collector(context).callMethod(
            context, "get", new IRubyObject[]{namespaceName, key, MetricExt.COUNTER}
        );
    }

    @Override
    protected IRubyObject getGauge(final ThreadContext context, final IRubyObject key,
        final IRubyObject value) {
        return metric.gauge(context, namespaceName, key, value);
    }

    @Override
    protected IRubyObject getTimer(ThreadContext context, IRubyObject key) {
        return metric.timer(context, namespaceName, key);
    }

    @Override
    protected IRubyObject doIncrement(final ThreadContext context, final IRubyObject[] args) {
        if (args.length == 1) {
            return metric.increment(context, namespaceName, args[0]);
        } else {
            return metric.increment(context, namespaceName, args[0], args[1]);
        }
    }

    @Override
    protected IRubyObject doDecrement(final ThreadContext context, final IRubyObject[] args) {
        if (args.length == 1) {
            return metric.decrement(context, namespaceName, args[0]);
        } else {
            return metric.decrement(context, namespaceName, args[0], args[1]);
        }
    }

    @Override
    protected IRubyObject doTime(final ThreadContext context, final IRubyObject key,
        final Block block) {
        return metric.time(context, namespaceName, key, block);
    }

    protected IRubyObject doReportTime(final ThreadContext context, final IRubyObject key,
        final IRubyObject duration) {
        return metric.reportTime(context, namespaceName, key, duration);
    }

    @Override
    @SuppressWarnings("rawtypes")
    protected RubyArray getNamespaceName(final ThreadContext context) {
        return namespaceName;
    }

    @Override
    protected NamespacedMetricExt createNamespaced(final ThreadContext context,
        final IRubyObject name) {
        MetricExt.validateName(context, name, RubyUtil.METRIC_NO_NAMESPACE_PROVIDED_CLASS);
        return create(this.metric, (RubyArray) namespaceName.op_plus(normalizeNamespace(name)));
    }

    @Override
    public AbstractMetricExt getMetric() { return this.metric; }
}
