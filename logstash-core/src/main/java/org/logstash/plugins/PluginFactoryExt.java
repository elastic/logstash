package org.logstash.plugins;

import java.util.Arrays;
import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyBasicObject;
import org.jruby.RubyClass;
import org.jruby.RubySymbol;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.execution.ExecutionContextExt;
import org.logstash.instrument.metrics.AbstractMetricExt;
import org.logstash.instrument.metrics.AbstractNamespacedMetricExt;
import org.logstash.instrument.metrics.NullMetricExt;

public final class PluginFactoryExt {

    @JRubyClass(name = "ExecutionContextFactory")
    public static final class ExecutionContext extends RubyBasicObject {

        private IRubyObject agent;

        private IRubyObject pipeline;

        private IRubyObject dlqWriter;

        public ExecutionContext(final Ruby runtime, final RubyClass metaClass) {
            super(runtime, metaClass);
        }

        @JRubyMethod
        public PluginFactoryExt.ExecutionContext initialize(final ThreadContext context,
            final IRubyObject agent, final IRubyObject pipeline, final IRubyObject dlqWriter) {
            this.agent = agent;
            this.pipeline = pipeline;
            this.dlqWriter = dlqWriter;
            return this;
        }

        @JRubyMethod
        public ExecutionContextExt create(final ThreadContext context, final IRubyObject id,
            final IRubyObject classConfigName) {
            return new ExecutionContextExt(
                context.runtime, RubyUtil.EXECUTION_CONTEXT_CLASS
            ).initialize(
                context, new IRubyObject[]{pipeline, agent, id, classConfigName, dlqWriter}
            );
        }
    }

    @JRubyClass(name = "PluginMetricFactory")
    public static final class Metrics extends RubyBasicObject {

        private static final RubySymbol STATS = RubyUtil.RUBY.newSymbol("stats");

        private static final RubySymbol PIPELINES = RubyUtil.RUBY.newSymbol("pipelines");

        private static final RubySymbol PLUGINS = RubyUtil.RUBY.newSymbol("plugins");

        private RubySymbol pipelineId;

        private AbstractMetricExt metric;

        public Metrics(final Ruby runtime, final RubyClass metaClass) {
            super(runtime, metaClass);
        }

        @JRubyMethod
        public PluginFactoryExt.Metrics initialize(final ThreadContext context,
            final IRubyObject pipelineId, final IRubyObject metrics) {
            this.pipelineId = pipelineId.convertToString().intern19();
            if (metrics.isNil()) {
                this.metric = new NullMetricExt(context.runtime, RubyUtil.NULL_METRIC_CLASS);
            } else {
                this.metric = (AbstractMetricExt) metrics;
            }
            return this;
        }

        @JRubyMethod
        public AbstractNamespacedMetricExt create(final ThreadContext context, final IRubyObject pluginType) {
            return metric.namespace(
                context,
                RubyArray.newArray(
                    context.runtime, Arrays.asList(STATS, PIPELINES, pipelineId, PLUGINS)
                )
            ).namespace(
                context, RubyUtil.RUBY.newSymbol(String.format("%ss", pluginType.asJavaString()))
            );
        }
    }
}
