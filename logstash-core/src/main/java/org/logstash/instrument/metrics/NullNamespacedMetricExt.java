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

    private static final RubySymbol NULL = RubyUtil.RUBY.newSymbol("null");

    private RubyArray namespaceName;

    private NullMetricExt metric;

    public static AbstractNamespacedMetricExt create(final NullMetricExt metric,
        final RubyArray namespaceName) {
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
        this.metric = args.length > 0 && !args[0].isNil() ? (NullMetricExt) args[0] : null;
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

    @JRubyClass(name = "NullCounter")
    public static final class NullCounter extends RubyObject {

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
