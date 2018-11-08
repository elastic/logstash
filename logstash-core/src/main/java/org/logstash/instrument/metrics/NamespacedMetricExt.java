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

    private RubyArray namespaceName;

    private MetricExt metric;

    public static NamespacedMetricExt create(final MetricExt metric,
        final RubyArray namespaceName) {
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
    public IRubyObject initialize(final ThreadContext context, final IRubyObject metric,
        final IRubyObject namespaceName) {
        this.metric = (MetricExt) metric;
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
    protected RubyArray getNamespaceName(final ThreadContext context) {
        return namespaceName;
    }

    @Override
    protected NamespacedMetricExt createNamespaced(final ThreadContext context,
        final IRubyObject name) {
        MetricExt.validateName(context, name, RubyUtil.METRIC_NO_NAMESPACE_PROVIDED_CLASS);
        return create(this.metric, (RubyArray) namespaceName.op_plus(
            name instanceof RubyArray ? name : RubyArray.newArray(context.runtime, name)
        ));
    }
}
