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

    private AbstractDeadLetterQueueWriterExt dlqWriter;

    private IRubyObject agent;

    private IRubyObject pipeline;

    public ExecutionContextExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @JRubyMethod(required = 5)
    public ExecutionContextExt initialize(final ThreadContext context,
        final IRubyObject[] args) {
        pipeline = args[0];
        agent = args[1];
        dlqWriter = new AbstractDeadLetterQueueWriterExt.PluginDeadLetterQueueWriterExt(
            context.runtime, RubyUtil.PLUGIN_DLQ_WRITER_CLASS
        ).initialize(context, args[4], args[2], args[3]);
        return this;
    }

    @JRubyMethod(name = "dlq_writer")
    public AbstractDeadLetterQueueWriterExt dlqWriter(final ThreadContext context) {
        return dlqWriter;
    }

    @JRubyMethod
    public IRubyObject agent(final ThreadContext context) {
        return agent;
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
