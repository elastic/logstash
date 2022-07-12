package org.logstash.plugins.factory;

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

/**
 * JRuby extension, factory class for plugins execution contexts
 * */
@JRubyClass(name = "ExecutionContextFactory")
public final class ExecutionContextFactoryExt extends RubyBasicObject {

    private static final long serialVersionUID = 1L;

    private transient IRubyObject agent;

    private transient IRubyObject pipeline;

    private transient IRubyObject dlqWriter;

    public ExecutionContextFactoryExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @JRubyMethod
    public ExecutionContextFactoryExt initialize(final ThreadContext context, final IRubyObject agent,
                                                 final IRubyObject pipeline, final IRubyObject dlqWriter) {
        this.agent = agent;
        this.pipeline = pipeline;
        this.dlqWriter = dlqWriter;
        return this;
    }

    @JRubyMethod
    public ExecutionContextExt create(final ThreadContext context, final IRubyObject id,
                                      final IRubyObject classConfigName) {
        final AbstractDeadLetterQueueWriterExt dlqWriterForInstance = new AbstractDeadLetterQueueWriterExt.PluginDeadLetterQueueWriterExt(
                context.runtime, RubyUtil.PLUGIN_DLQ_WRITER_CLASS
        ).initialize(context, dlqWriter, id, classConfigName);

        return new ExecutionContextExt(
            context.runtime, RubyUtil.EXECUTION_CONTEXT_CLASS
        ).initialize(
            context, new IRubyObject[]{pipeline, agent, dlqWriterForInstance}
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

        return new ContextImpl(dlq, new NamespacedMetricImpl(RubyUtil.RUBY.getCurrentContext(), metric));
    }

    IRubyObject getPipeline() {
        return pipeline;
    }
}
