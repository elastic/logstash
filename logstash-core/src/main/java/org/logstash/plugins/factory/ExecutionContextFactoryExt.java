package org.logstash.plugins.factory;

import co.elastic.logstash.api.AcknowledgeBus;
import co.elastic.logstash.api.Context;
import co.elastic.logstash.api.DeadLetterQueueWriter;
import org.jruby.Ruby;
import org.jruby.RubyBasicObject;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.common.AbstractDeadLetterQueueWriterExt;
import org.logstash.common.DLQWriterAdapter;
import org.logstash.common.NullDeadLetterQueueWriter;
import org.logstash.execution.ExecutionContextExt;
import org.logstash.instrument.metrics.AbstractNamespacedMetricExt;
import org.logstash.plugins.ContextImpl;
import org.logstash.plugins.NamespacedMetricImpl;
import org.logstash.plugins.PluginLookup;

@JRubyClass(name = "ExecutionContextFactory")
public final class ExecutionContextFactoryExt extends RubyBasicObject {

    private static final long serialVersionUID = 1L;

    private IRubyObject agent;

    private IRubyObject pipeline;

    private IRubyObject dlqWriter;

    private AcknowledgeBus acknowledgeBus;

    public ExecutionContextFactoryExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @JRubyMethod
    public ExecutionContextFactoryExt initialize(final ThreadContext context, final IRubyObject agent,
                                                 final IRubyObject pipeline, final IRubyObject dlqWriter) {
        this.agent = agent;
        this.pipeline = pipeline;
        this.dlqWriter = dlqWriter;
        this.acknowledgeBus = null;
        if (agent != null && !agent.isNil()){
            IRubyObject bus = agent.callMethod(RubyUtil.RUBY.getCurrentContext(), "acknowledge_bus");
            if (bus != null && !bus.isNil() && AcknowledgeBus.class.isAssignableFrom(bus.getJavaClass())){
                this.acknowledgeBus = bus.toJava(AcknowledgeBus.class);
            }
        }
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

    Context toContext(PluginLookup.PluginType pluginType, AbstractNamespacedMetricExt metric) {
        DeadLetterQueueWriter dlq = NullDeadLetterQueueWriter.getInstance();
        if (dlqWriter instanceof AbstractDeadLetterQueueWriterExt.PluginDeadLetterQueueWriterExt) {
            IRubyObject innerWriter =
                    ((AbstractDeadLetterQueueWriterExt.PluginDeadLetterQueueWriterExt) dlqWriter)
                            .innerWriter(RubyUtil.RUBY.getCurrentContext());
            if (innerWriter != null) {
                if (org.logstash.common.io.DeadLetterQueueWriter.class.isAssignableFrom(innerWriter.getJavaClass())) {
                    dlq = new DLQWriterAdapter(innerWriter.toJava(org.logstash.common.io.DeadLetterQueueWriter.class));
                }
            }
        } else if (dlqWriter.getJavaClass().equals(DeadLetterQueueWriter.class)) {
            dlq = dlqWriter.toJava(DeadLetterQueueWriter.class);
        }
        AcknowledgeBus ack_bus = null;
        if (pluginType == PluginLookup.PluginType.INPUT){
            ack_bus = this.acknowledgeBus;
        }

        return new ContextImpl(dlq, new NamespacedMetricImpl(RubyUtil.RUBY.getCurrentContext(), metric), ack_bus);
    }

    IRubyObject getPipeline() {
        return pipeline;
    }
}
