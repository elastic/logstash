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

@JRubyClass(name = "NullMetric")
public final class NullMetricExt extends AbstractSimpleMetricExt {

    private IRubyObject collector;

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
