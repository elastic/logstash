package org.logstash.execution;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.common.AbstractDeadLetterQueueWriterExt;

@JRubyClass(name = "ExecutionContext")
public final class ExecutionContextExt extends RubyObject {

    private static final long serialVersionUID = 1L;

    private AbstractDeadLetterQueueWriterExt dlqWriter;

    private IRubyObject pipeline;

    public ExecutionContextExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @JRubyMethod(required = 4)
    public ExecutionContextExt initialize(final ThreadContext context, final IRubyObject[] args) {
        pipeline = args[0];
        final IRubyObject pluginId = args[1];
        final IRubyObject pluginType = args[2];
        final IRubyObject _dlqWriter = args[3];

        dlqWriter = new AbstractDeadLetterQueueWriterExt.PluginDeadLetterQueueWriterExt(
            context.runtime, RubyUtil.PLUGIN_DLQ_WRITER_CLASS
        ).initialize(context, _dlqWriter, pluginId, pluginType);
        return this;
    }

    @JRubyMethod(name = "dlq_writer")
    public AbstractDeadLetterQueueWriterExt dlqWriter(final ThreadContext context) {
        return dlqWriter;
    }
    
    @JRubyMethod
    public IRubyObject pipeline(final ThreadContext context) {
        return pipeline;
    }

    @JRubyMethod(name = "pipeline_id")
    public IRubyObject pipelineId(final ThreadContext context) {
        return pipeline.callMethod(context, "pipeline_id");
    }
}
