/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *	http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */


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
