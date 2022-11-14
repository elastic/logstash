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
import org.jruby.runtime.builtin.IRubyObject;

@JRubyClass(name = "AbstractNamespacedMetric")
public abstract class AbstractNamespacedMetricExt extends AbstractMetricExt {

    private static final long serialVersionUID = 1L;

    AbstractNamespacedMetricExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @JRubyMethod
    public IRubyObject counter(final ThreadContext context, final IRubyObject key) {
        return getCounter(context, key);
    }

    @JRubyMethod
    public IRubyObject gauge(final ThreadContext context, final IRubyObject key,
        final IRubyObject value) {
        return getGauge(context, key, value);
    }
    @JRubyMethod
    public IRubyObject timer(final ThreadContext context, final IRubyObject key) {
        return getTimer(context, key);
    }

    @JRubyMethod(required = 1, optional = 1)
    public IRubyObject increment(final ThreadContext context, final IRubyObject[] args) {
        return doIncrement(context, args);
    }

    @JRubyMethod(required = 1, optional = 1)
    public IRubyObject decrement(final ThreadContext context, final IRubyObject[] args) {
        return doDecrement(context, args);
    }

    @JRubyMethod
    public IRubyObject time(final ThreadContext context, final IRubyObject key, final Block block) {
        return doTime(context, key, block);
    }

    @JRubyMethod(name = "report_time")
    public IRubyObject reportTime(final ThreadContext context, final IRubyObject key,
        final IRubyObject duration) {
        return doReportTime(context, key, duration);
    }

    @JRubyMethod(name = "namespace_name")
    @SuppressWarnings("rawtypes")
    public RubyArray namespaceName(final ThreadContext context) {
        return getNamespaceName(context);
    }

    @JRubyMethod(name = "root")
    public AbstractMetricExt root(final ThreadContext context) {
        return getMetric();
    }

    protected abstract IRubyObject getGauge(ThreadContext context, IRubyObject key,
        IRubyObject value);

    @SuppressWarnings("rawtypes")
    protected abstract RubyArray getNamespaceName(ThreadContext context);

    protected abstract IRubyObject getCounter(ThreadContext context, IRubyObject key);

    protected abstract IRubyObject getTimer(ThreadContext context, IRubyObject key);

    protected abstract IRubyObject doTime(ThreadContext context, IRubyObject key, Block block);

    protected abstract IRubyObject doReportTime(ThreadContext context,
        IRubyObject key, IRubyObject duration);

    protected abstract IRubyObject doIncrement(ThreadContext context, IRubyObject[] args);

    protected abstract IRubyObject doDecrement(ThreadContext context, IRubyObject[] args);

    public abstract AbstractMetricExt getMetric();
}
