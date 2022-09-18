package org.logstash.plugins.factory;

import org.jruby.*;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.instrument.metrics.AbstractMetricExt;
import org.logstash.instrument.metrics.AbstractNamespacedMetricExt;
import org.logstash.instrument.metrics.NullMetricExt;

import java.util.Arrays;

import static org.logstash.instrument.metrics.MetricKeys.*;

/**
 * JRuby extension to implement a factory class for Plugin's metrics
 * */
@JRubyClass(name = "PluginMetricsFactory")
public final class PluginMetricsFactoryExt extends RubyBasicObject {

    private static final long serialVersionUID = 1L;

    private RubySymbol pipelineId;

    private AbstractMetricExt metric;

    public PluginMetricsFactoryExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @JRubyMethod
    public PluginMetricsFactoryExt initialize(final ThreadContext context,
                                              final IRubyObject pipelineId, final IRubyObject metrics) {
        this.pipelineId = pipelineId.convertToString().intern();
        if (metrics.isNil()) {
            this.metric = new NullMetricExt(context.runtime, RubyUtil.NULL_METRIC_CLASS);
        } else {
            this.metric = (AbstractMetricExt) metrics;
        }
        return this;
    }

    AbstractNamespacedMetricExt getRoot(final ThreadContext context) {
        return metric.namespace(
            context,
            RubyArray.newArray(
                context.runtime,
                Arrays.asList(STATS_KEY, PIPELINES_KEY, pipelineId, PLUGINS_KEY)));
    }

    @JRubyMethod
    public AbstractNamespacedMetricExt create(final ThreadContext context, final IRubyObject pluginType) {
        return getRoot(context).namespace(
            context, RubyUtil.RUBY.newSymbol(String.format("%ss", pluginType.asJavaString()))
        );
    }
}
