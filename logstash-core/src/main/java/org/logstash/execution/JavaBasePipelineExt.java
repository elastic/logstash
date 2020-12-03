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

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyBoolean;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.common.IncompleteSourceWithMetadataException;
import org.logstash.config.ir.CompiledPipeline;
import org.logstash.execution.queue.QueueWriter;
import org.logstash.ext.JRubyWrappedWriteClientExt;
import org.logstash.plugins.factory.ExecutionContextFactoryExt;
import org.logstash.plugins.factory.PluginMetricsFactoryExt;
import org.logstash.plugins.factory.PluginFactoryExt;

import java.security.NoSuchAlgorithmException;
import java.util.Collection;
import java.util.stream.Stream;

@JRubyClass(name = "JavaBasePipeline")
public final class JavaBasePipelineExt extends AbstractPipelineExt {

    private static final long serialVersionUID = 1L;

    private static final Logger LOGGER = LogManager.getLogger(JavaBasePipelineExt.class);

    private CompiledPipeline lirExecution;

    private @SuppressWarnings("rawtypes") RubyArray inputs;

    private @SuppressWarnings("rawtypes") RubyArray filters;

    private @SuppressWarnings("rawtypes") RubyArray outputs;

    public JavaBasePipelineExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @JRubyMethod(required = 4)
    public JavaBasePipelineExt initialize(final ThreadContext context, final IRubyObject[] args)
        throws IncompleteSourceWithMetadataException, NoSuchAlgorithmException {
        initialize(context, args[0], args[1], args[2]);
        lirExecution = new CompiledPipeline(
            lir,
            new PluginFactoryExt(context.runtime, RubyUtil.PLUGIN_FACTORY_CLASS).init(
                lir,
                new PluginMetricsFactoryExt(
                    context.runtime, RubyUtil.PLUGIN_METRICS_FACTORY_CLASS
                ).initialize(context, pipelineId(), metric()),
                new ExecutionContextFactoryExt(
                    context.runtime, RubyUtil.EXECUTION_CONTEXT_FACTORY_CLASS
                ).initialize(context, args[3], this, dlqWriter(context)),
                RubyUtil.FILTER_DELEGATOR_CLASS
            ),
            getSecretStore(context)
        );
        inputs = RubyArray.newArray(context.runtime, lirExecution.inputs());
        filters = RubyArray.newArray(context.runtime, lirExecution.filters());
        outputs = RubyArray.newArray(context.runtime, lirExecution.outputs());
        if (getSetting(context, "config.debug").isTrue() && LOGGER.isDebugEnabled()) {
            LOGGER.debug(
                "Compiled pipeline code for pipeline {} : {}", pipelineId(),
                lir.getGraph().toString()
            );
        }
        return this;
    }

    @JRubyMethod(name = "lir_execution")
    public IRubyObject lirExecution(final ThreadContext context) {
        return JavaUtil.convertJavaToUsableRubyObject(context.runtime, lirExecution);
    }

    @JRubyMethod
    @SuppressWarnings("rawtypes")
    public RubyArray inputs() {
        return inputs;
    }

    @JRubyMethod
    @SuppressWarnings("rawtypes")
    public RubyArray filters() {
        return filters;
    }

    @JRubyMethod
    @SuppressWarnings("rawtypes")
    public RubyArray outputs() {
        return outputs;
    }

    @JRubyMethod(name = "reloadable?")
    public RubyBoolean isReloadable(final ThreadContext context) {
        return isConfiguredReloadable(context).isTrue() && reloadablePlugins(context).isTrue()
            ? context.tru : context.fals;
    }

    @JRubyMethod(name = "reloadable_plugins?")
    public RubyBoolean reloadablePlugins(final ThreadContext context) {
        return nonReloadablePlugins(context).isEmpty() ? context.tru : context.fals;
    }

    @SuppressWarnings({"unchecked", "rawtypes"})
    @JRubyMethod(name = "non_reloadable_plugins")
    public RubyArray nonReloadablePlugins(final ThreadContext context) {
        final RubyArray result = RubyArray.newArray(context.runtime);
        Stream.of(inputs, outputs, filters).flatMap(
            plugins -> ((Collection<IRubyObject>) plugins).stream()
        ).filter(
            plugin -> !plugin.callMethod(context, "reloadable?").isTrue()
        ).forEach(result::add);
        return result;
    }

    public QueueWriter getQueueWriter(final String inputName) {
        return new JRubyWrappedWriteClientExt(RubyUtil.RUBY, RubyUtil.WRAPPED_WRITE_CLIENT_CLASS)
            .initialize(
                RubyUtil.RUBY.getCurrentContext(),
                new IRubyObject[]{
                    inputQueueClient(), pipelineId().convertToString().intern(),
                    metric(), RubyUtil.RUBY.newSymbol(inputName)
                }
            );
    }
}
