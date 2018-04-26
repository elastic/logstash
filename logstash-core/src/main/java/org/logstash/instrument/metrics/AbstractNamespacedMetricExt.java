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
    public RubyArray namespaceName(final ThreadContext context) {
        return getNamespaceName(context);
    }

    protected abstract IRubyObject getGauge(ThreadContext context, IRubyObject key,
        IRubyObject value);

    protected abstract RubyArray getNamespaceName(ThreadContext context);

    protected abstract IRubyObject getCounter(ThreadContext context, IRubyObject key);

    protected abstract IRubyObject doTime(ThreadContext context, IRubyObject key, Block block);

    protected abstract IRubyObject doReportTime(ThreadContext context,
        IRubyObject key, IRubyObject duration);

    protected abstract IRubyObject doIncrement(ThreadContext context, IRubyObject[] args);

    protected abstract IRubyObject doDecrement(ThreadContext context, IRubyObject[] args);
}
