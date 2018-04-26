package org.logstash.instrument.metrics;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.Block;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

@JRubyClass(name = "AbstractSimpleMetric")
public abstract class AbstractSimpleMetricExt extends AbstractMetricExt {

    AbstractSimpleMetricExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @JRubyMethod(required = 2, optional = 1)
    public IRubyObject increment(final ThreadContext context, final IRubyObject[] args) {
        return doIncrement(context, args);
    }

    @JRubyMethod(required = 2, optional = 1)
    public IRubyObject decrement(final ThreadContext context, final IRubyObject[] args) {
        return doDecrement(context, args);
    }

    @JRubyMethod
    public IRubyObject gauge(final ThreadContext context, final IRubyObject namespace,
        final IRubyObject key, final IRubyObject value) {
        return getGauge(context, namespace, key, value);
    }

    @JRubyMethod(name = "report_time")
    public IRubyObject reportTime(final ThreadContext context, final IRubyObject namespace,
        final IRubyObject key, final IRubyObject duration) {
        return doReportTime(context, namespace, key, duration);
    }

    @JRubyMethod
    public IRubyObject time(final ThreadContext context, final IRubyObject namespace,
        final IRubyObject key, final Block block) {
        return doTime(context, namespace, key, block);
    }

    protected abstract IRubyObject doDecrement(ThreadContext context, IRubyObject[] args);

    protected abstract IRubyObject doIncrement(ThreadContext context, IRubyObject[] args);

    protected abstract IRubyObject getGauge(ThreadContext context, IRubyObject namespace,
        IRubyObject key, IRubyObject value);

    protected abstract IRubyObject doReportTime(ThreadContext context, IRubyObject namespace,
        IRubyObject key, IRubyObject duration);

    protected abstract IRubyObject doTime(ThreadContext context, IRubyObject namespace,
        IRubyObject key, Block block);
}
