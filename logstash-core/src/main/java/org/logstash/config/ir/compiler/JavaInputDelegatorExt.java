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


package org.logstash.config.ir.compiler;

import co.elastic.logstash.api.Input;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.execution.AbstractPipelineExt;
import org.logstash.execution.queue.QueueWriter;
import org.logstash.instrument.metrics.AbstractNamespacedMetricExt;
import org.logstash.instrument.metrics.MetricKeys;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.function.Function;

@JRubyClass(name = "JavaInputDelegator")
public class JavaInputDelegatorExt extends RubyObject {
    private static final long serialVersionUID = 1L;

    private AbstractNamespacedMetricExt metric;

    private AbstractPipelineExt pipeline;

    private transient Input input;

    private transient DecoratingQueueWriter decoratingQueueWriter;

    public JavaInputDelegatorExt(Ruby runtime, RubyClass metaClass) {
        super(runtime, metaClass);
    }

    public static JavaInputDelegatorExt create(final AbstractPipelineExt pipeline,
                                               final AbstractNamespacedMetricExt metric, final Input input,
                                               final Map<String, Object> pluginArgs) {
        final JavaInputDelegatorExt instance =
                new JavaInputDelegatorExt(RubyUtil.RUBY, RubyUtil.JAVA_INPUT_DELEGATOR_CLASS);
        AbstractNamespacedMetricExt scopedMetric = metric.namespace(RubyUtil.RUBY.getCurrentContext(), RubyUtil.RUBY.newSymbol(input.getId()));
        scopedMetric.gauge(RubyUtil.RUBY.getCurrentContext(), MetricKeys.NAME_KEY, RubyUtil.RUBY.newString(input.getName()));
        instance.setMetric(RubyUtil.RUBY.getCurrentContext(), scopedMetric);
        instance.input = input;
        instance.pipeline = pipeline;
        instance.initializeQueueWriter(pluginArgs);
        return instance;
    }

    @JRubyMethod(name = "start")
    public IRubyObject start(final ThreadContext context) {
        QueueWriter qw = pipeline.getQueueWriter(input.getId());
        final QueueWriter queueWriter;
        if (decoratingQueueWriter != null) {
            decoratingQueueWriter.setInnerQueueWriter(qw);
            queueWriter = decoratingQueueWriter;
        } else {
            queueWriter = qw;
        }
        Thread t = new Thread(() -> {
            org.apache.logging.log4j.ThreadContext.put("pipeline.id", pipeline.pipelineId().toString());
            org.apache.logging.log4j.ThreadContext.put("plugin.id", this.getId(context).toString());
            input.start(queueWriter::push);
        });
        t.setName(pipeline.pipelineId().asJavaString() + "_" + input.getName() + "_" + input.getId());
        t.start();
        return RubyUtil.toRubyObject(t);
    }

    @JRubyMethod(name = "metric=")
    public IRubyObject setMetric(final ThreadContext context, final IRubyObject metric) {
        this.metric = (AbstractNamespacedMetricExt) metric;
        return this;
    }

    @JRubyMethod(name = "metric")
    public IRubyObject getMetric(final ThreadContext context) {
        return this.metric;
    }

    @JRubyMethod(name = "config_name", meta = true)
    public IRubyObject configName(final ThreadContext context) {
        return context.getRuntime().newString(input.getName());
    }

    @JRubyMethod(name = "id")
    public IRubyObject getId(final ThreadContext context) {
        return context.getRuntime().newString(input.getId());
    }

    @JRubyMethod(name = "threadable")
    public IRubyObject isThreadable(final ThreadContext context) {
        return context.fals;
    }

    @JRubyMethod(name = "register")
    public IRubyObject register(final ThreadContext context) {
        return this;
    }

    @JRubyMethod(name = "do_close")
    public IRubyObject close(final ThreadContext context) {
        return this;
    }

    @JRubyMethod(name = "stop?")
    public IRubyObject isStopping(final ThreadContext context) {
        return context.fals;
    }

    @JRubyMethod(name = "do_stop")
    public IRubyObject doStop(final ThreadContext context) {
        try {
            input.stop();
            input.awaitStop();
        } catch (InterruptedException ex) {
            // do nothing
        }
        return this;
    }

    @JRubyMethod(name = "reloadable?")
    public IRubyObject isReloadable(final ThreadContext context) {
        return context.tru;
    }

    @SuppressWarnings("unchecked")
    private void initializeQueueWriter(Map<String, Object> pluginArgs) {
        List<Function<Map<String, Object>, Map<String, Object>>> inputActions = new ArrayList<>();
        for (Map.Entry<String, Object> entry : pluginArgs.entrySet()) {
            Function<Map<String, Object>, Map<String, Object>> inputAction =
                    CommonActions.getInputAction(entry);
            if (inputAction != null) {
                inputActions.add(inputAction);
            }
        }

        if (inputActions.size() == 0) {
            this.decoratingQueueWriter = null;
        } else {
            this.decoratingQueueWriter = new DecoratingQueueWriter(inputActions);
        }
    }

    static class DecoratingQueueWriter implements QueueWriter {

        private QueueWriter innerQueueWriter;

        private final List<Function<Map<String, Object>, Map<String, Object>>> inputActions;

        DecoratingQueueWriter(List<Function<Map<String, Object>, Map<String, Object>>> inputActions) {
            this.inputActions = inputActions;
        }

        @Override
        public void push(Map<String, Object> event) {
            for (Function<Map<String, Object>, Map<String, Object>> action : inputActions) {
                event = action.apply(event);
            }
            innerQueueWriter.push(event);
        }

        private void setInnerQueueWriter(QueueWriter innerQueueWriter) {
            this.innerQueueWriter = innerQueueWriter;
        }
    }
}
