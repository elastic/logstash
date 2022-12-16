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

import com.google.common.annotations.VisibleForTesting;
import java.util.Collection;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyHash;
import org.jruby.RubyString;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.Block;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.execution.ExecutionContextExt;
import org.logstash.ext.JrubyEventExtLibrary;
import org.logstash.instrument.metrics.AbstractMetricExt;

import static org.logstash.RubyUtil.RUBY;

@JRubyClass(name = "OutputDelegator")
public final class OutputDelegatorExt extends AbstractOutputDelegatorExt {

    private static final long serialVersionUID = 1L;

    private transient IRubyObject outputClass;

    private OutputStrategyExt.AbstractOutputStrategyExt strategy;

    @JRubyMethod(required = 5)
    public OutputDelegatorExt initialize(final ThreadContext context, final IRubyObject[] arguments) {
        ExecutionContextExt executionContext = (ExecutionContextExt) arguments[2];
        RubyClass klass = (RubyClass) arguments[0];
        AbstractMetricExt metric = (AbstractMetricExt) arguments[1];
        OutputStrategyExt.OutputStrategyRegistryExt strategyRegistry = (OutputStrategyExt.OutputStrategyRegistryExt) arguments[3];
        RubyHash args = (RubyHash) arguments[4];
        return initialize(
            context,
            args,
            klass,
            metric,
            executionContext,
            strategyRegistry
        );
    }

    public OutputDelegatorExt initialize(final ThreadContext context,
                                         final RubyHash args,
                                         final RubyClass outputClass,
                                         final AbstractMetricExt metric,
                                         final ExecutionContextExt executionContext,
                                         final OutputStrategyExt.OutputStrategyRegistryExt strategyRegistry) {
        this.outputClass = outputClass;
        initMetrics(
            args.op_aref(context, RubyString.newString(context.runtime, "id")).asJavaString(),
            metric
        );
        strategy = (OutputStrategyExt.AbstractOutputStrategyExt) strategyRegistry.classFor(
            context, concurrency(context)
        ).newInstance(
            context, new IRubyObject[]{outputClass, namespacedMetric, executionContext, args},
            Block.NULL_BLOCK
        );
        return this;
    }

    public OutputDelegatorExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @JRubyMethod
    @VisibleForTesting
    public OutputStrategyExt.AbstractOutputStrategyExt strategy() {
        return strategy;
    }

    @Override
    protected IRubyObject getConfigName(final ThreadContext context) {
        return outputClass.callMethod(context, "config_name");
    }

    @Override
    protected IRubyObject getConcurrency(final ThreadContext context) {
        return outputClass.callMethod(context, "concurrency");
    }

    @Override
    protected void doOutput(final Collection<JrubyEventExtLibrary.RubyEvent> batch) {
        try {
            final IRubyObject pluginId = this.getId();
            org.apache.logging.log4j.ThreadContext.put("plugin.id", pluginId.toString());
            strategy.multiReceive(RUBY.getCurrentContext(), (IRubyObject) batch);
        } catch (final InterruptedException ex) {
            throw new IllegalStateException(ex);
        } finally {
            org.apache.logging.log4j.ThreadContext.remove("plugin.id");
        }
    }

    @Override
    protected void close(final ThreadContext context) {
        strategy.doClose(context);
    }

    @Override
    protected void doRegister(final ThreadContext context) {
        strategy.register(context);
    }

    @Override
    protected IRubyObject reloadable(final ThreadContext context) {
        return outputClass.callMethod(context, "reloadable?");
    }

}
