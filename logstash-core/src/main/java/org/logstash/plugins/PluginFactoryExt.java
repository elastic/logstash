package org.logstash.plugins;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyBasicObject;
import org.jruby.RubyClass;
import org.jruby.RubyHash;
import org.jruby.RubyInteger;
import org.jruby.RubyString;
import org.jruby.RubySymbol;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.config.ir.PipelineIR;
import org.logstash.config.ir.compiler.AbstractFilterDelegatorExt;
import org.logstash.config.ir.compiler.AbstractOutputDelegatorExt;
import org.logstash.config.ir.compiler.FilterDelegatorExt;
import org.logstash.config.ir.compiler.JavaFilterDelegatorExt;
import org.logstash.config.ir.compiler.JavaOutputDelegatorExt;
import org.logstash.config.ir.compiler.OutputDelegatorExt;
import org.logstash.config.ir.compiler.OutputStrategyExt;
import org.logstash.config.ir.compiler.RubyIntegration;
import org.logstash.config.ir.graph.Vertex;
import org.logstash.execution.ExecutionContextExt;
import org.logstash.execution.Filter;
import org.logstash.execution.Output;
import org.logstash.instrument.metrics.AbstractMetricExt;
import org.logstash.instrument.metrics.AbstractNamespacedMetricExt;
import org.logstash.instrument.metrics.MetricKeys;
import org.logstash.instrument.metrics.NullMetricExt;

import java.util.Arrays;
import java.util.Collection;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;

public final class PluginFactoryExt {

    @JRubyClass(name = "PluginFactory")
    public static final class Plugins extends RubyBasicObject
        implements RubyIntegration.PluginFactory {

        private static final RubyString ID_KEY = RubyUtil.RUBY.newString("id");

        private final Collection<String> pluginsById = new HashSet<>();

        private PipelineIR lir;

        private PluginFactoryExt.ExecutionContext executionContext;

        private PluginFactoryExt.Metrics metrics;

        private RubyClass filterClass;

        @JRubyMethod(name = "filter_delegator", meta = true, required = 5)
        public static IRubyObject filterDelegator(final ThreadContext context,
            final IRubyObject recv, final IRubyObject[] args) {
            final RubyHash arguments = (RubyHash) args[2];
            final IRubyObject filterInstance = args[1].callMethod(context, "new", arguments);
            final RubyString id = (RubyString) arguments.op_aref(context, ID_KEY);
            filterInstance.callMethod(
                context, "metric=",
                ((AbstractMetricExt) args[3]).namespace(context, id.intern19())
            );
            filterInstance.callMethod(context, "execution_context=", args[4]);
            FilterDelegatorExt fd = (FilterDelegatorExt) new FilterDelegatorExt(context.runtime, RubyUtil.FILTER_DELEGATOR_CLASS)
                    .initialize(context, filterInstance, id);
            return fd;
        }

        public Plugins(final Ruby runtime, final RubyClass metaClass) {
            super(runtime, metaClass);
        }

        @JRubyMethod(required = 4)
        public PluginFactoryExt.Plugins initialize(final ThreadContext context,
            final IRubyObject[] args) {
            return init(
                (PipelineIR) args[0].toJava(PipelineIR.class),
                (PluginFactoryExt.Metrics) args[1], (PluginFactoryExt.ExecutionContext) args[2],
                (RubyClass) args[3]
            );
        }

        public PluginFactoryExt.Plugins init(final PipelineIR lir,
            final PluginFactoryExt.Metrics metrics,
            final PluginFactoryExt.ExecutionContext executionContext, final RubyClass filterClass) {
            this.lir = lir;
            this.metrics = metrics;
            this.executionContext = executionContext;
            this.filterClass = filterClass;
            return this;
        }

        @SuppressWarnings("unchecked")
        @Override
        public IRubyObject buildInput(final RubyString name, final RubyInteger line,
            final RubyInteger column, final IRubyObject args) {
            return plugin(
                RubyUtil.RUBY.getCurrentContext(), PluginLookup.PluginType.INPUT,
                name.asJavaString(), line.getIntValue(), column.getIntValue(),
                (Map<String, IRubyObject>) args
            );
        }

        @JRubyMethod(required = 4)
        public IRubyObject buildInput(final ThreadContext context, final IRubyObject[] args) {
            return buildInput(
                (RubyString) args[0], args[1].convertToInteger(), args[2].convertToInteger(),
                args[3]
            );
        }

        @SuppressWarnings("unchecked")
        @Override
        public AbstractOutputDelegatorExt buildOutput(final RubyString name, final RubyInteger line,
            final RubyInteger column, final IRubyObject args) {
            return (OutputDelegatorExt) plugin(
                RubyUtil.RUBY.getCurrentContext(), PluginLookup.PluginType.OUTPUT,
                name.asJavaString(), line.getIntValue(), column.getIntValue(),
                (Map<String, IRubyObject>) args
            );
        }

        @JRubyMethod(required = 4)
        public AbstractOutputDelegatorExt buildOutput(final ThreadContext context,
            final IRubyObject[] args) {
            return buildOutput(
                (RubyString) args[0], args[1].convertToInteger(), args[2].convertToInteger(), args[3]
            );
        }

        @Override
        public AbstractOutputDelegatorExt buildJavaOutput(final String name, final int line, final int column,
                                                          Output output, final IRubyObject args) {
            return (AbstractOutputDelegatorExt) plugin(
                    RubyUtil.RUBY.getCurrentContext(), PluginLookup.PluginType.OUTPUT,
                    name, line, column, (Map<String, IRubyObject>) args, true, output);
        }

        @SuppressWarnings("unchecked")
        @Override
        public AbstractFilterDelegatorExt buildFilter(final RubyString name, final RubyInteger line,
                                                      final RubyInteger column, final IRubyObject args) {
            return (AbstractFilterDelegatorExt) plugin(
                RubyUtil.RUBY.getCurrentContext(), PluginLookup.PluginType.FILTER,
                name.asJavaString(), line.getIntValue(), column.getIntValue(),
                (Map<String, IRubyObject>) args
            );
        }

        @JRubyMethod(required = 4)
        public IRubyObject buildFilter(final ThreadContext context, final IRubyObject[] args) {
            return buildFilter(
                (RubyString) args[0], args[1].convertToInteger(), args[2].convertToInteger(),
                args[3]
            );
        }

        @Override
        public AbstractFilterDelegatorExt buildJavaFilter(final String name, final int line, final int column,
                                                          Filter filter, final IRubyObject args) {
            return (AbstractFilterDelegatorExt) plugin(
                    RubyUtil.RUBY.getCurrentContext(), PluginLookup.PluginType.FILTER,
                    name, line, column, (Map<String, IRubyObject>) args, true, filter);
        }

        @SuppressWarnings("unchecked")
        @Override
        public IRubyObject buildCodec(final RubyString name, final IRubyObject args) {
            return plugin(
                RubyUtil.RUBY.getCurrentContext(), PluginLookup.PluginType.CODEC,
                name.asJavaString(), 0, 0, (Map<String, IRubyObject>) args
            );
        }

        @JRubyMethod(required = 4)
        public IRubyObject buildCodec(final ThreadContext context, final IRubyObject[] args) {
            return buildCodec((RubyString) args[0], args[1]);
        }

        @SuppressWarnings("unchecked")
        @JRubyMethod(required = 4, optional = 1)
        public IRubyObject plugin(final ThreadContext context, final IRubyObject[] args) {
            return plugin(
                context,
                PluginLookup.PluginType.valueOf(args[0].asJavaString().toUpperCase(Locale.ENGLISH)),
                args[1].asJavaString(),
                args[2].convertToInteger().getIntValue(),
                args[3].convertToInteger().getIntValue(),
                args.length > 4 ? (Map<String, IRubyObject>) args[4] : new HashMap<>()
            );
        }

        private IRubyObject plugin(final ThreadContext context,
                                   final PluginLookup.PluginType type, final String name, final int line, final int column,
                                   final Map<String, IRubyObject> args) {
            return plugin(context, type, name, line, column, args, false, null);
        }

        private IRubyObject plugin(final ThreadContext context,
            final PluginLookup.PluginType type, final String name, final int line, final int column,
            final Map<String, IRubyObject> args, boolean isJava, Object javaPlugin) {
            final String id;
            if (type == PluginLookup.PluginType.CODEC) {
                id = UUID.randomUUID().toString();
            } else {
                id = lir.getGraph().vertices().filter(
                    v -> v.getSourceWithMetadata() != null
                        && v.getSourceWithMetadata().getLine() == line
                        && v.getSourceWithMetadata().getColumn() == column
                ).findFirst().map(Vertex::getId).orElse(null);
            }
            if (id == null) {
                throw context.runtime.newRaiseException(
                    RubyUtil.CONFIGURATION_ERROR_CLASS,
                    String.format(
                        "Could not determine ID for %s/%s", type.rubyLabel().asJavaString(), name
                    )
                );
            }
            if (pluginsById.contains(id)) {
                throw context.runtime.newRaiseException(
                    RubyUtil.CONFIGURATION_ERROR_CLASS,
                    String.format("Two plugins have the id '%s', please fix this conflict", id)
                );
            }
            pluginsById.add(id);
            final AbstractNamespacedMetricExt typeScopedMetric = metrics.create(context, type.rubyLabel());

            if (!isJava) {
                final PluginLookup.PluginClass pluginClass = PluginLookup.lookup(type, name);
                final Map<String, Object> newArgs = new HashMap<>(args);
                newArgs.put("id", id);
                final RubyClass klass = (RubyClass) pluginClass.klass();
                final ExecutionContextExt executionCntx = executionContext.create(
                    context, RubyUtil.RUBY.newString(id), klass.callMethod(context, "config_name")
                );
                final RubyHash rubyArgs = RubyHash.newHash(context.runtime);
                rubyArgs.putAll(newArgs);
                if (type == PluginLookup.PluginType.OUTPUT) {
                    return new OutputDelegatorExt(context.runtime, RubyUtil.RUBY_OUTPUT_DELEGATOR_CLASS).initialize(
                        context,
                        new IRubyObject[]{
                            klass, typeScopedMetric, executionCntx,
                            OutputStrategyExt.OutputStrategyRegistryExt.instance(context, null),
                            rubyArgs
                        }
                    );
                } else if (type == PluginLookup.PluginType.FILTER) {
                    return filterDelegator(
                        context, null,
                        new IRubyObject[]{
                            filterClass, klass, rubyArgs, typeScopedMetric, executionCntx
                        }
                    );
                } else {
                    final IRubyObject pluginInstance = klass.callMethod(context, "new", rubyArgs);
                    final AbstractNamespacedMetricExt scopedMetric = typeScopedMetric.namespace(context, RubyUtil.RUBY.newSymbol(id));
                    scopedMetric.gauge(context, MetricKeys.NAME_KEY, pluginInstance.callMethod(context, "config_name"));
                    pluginInstance.callMethod(context, "metric=", scopedMetric);
                    pluginInstance.callMethod(context, "execution_context=", executionCntx);
                    return pluginInstance;
                }
            } else {
                if (type == PluginLookup.PluginType.OUTPUT) {
                    return JavaOutputDelegatorExt.create(name, id, typeScopedMetric, (Output)javaPlugin);
                } else if (type == PluginLookup.PluginType.FILTER) {
                    return JavaFilterDelegatorExt.create(name, id, typeScopedMetric, (Filter)javaPlugin);
                } else {
                    return context.nil;
                }
            }
        }
    }

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
                    context.runtime,
                    Arrays.asList(
                        MetricKeys.STATS_KEY, MetricKeys.PIPELINES_KEY, pipelineId, PLUGINS
                    )
                )
            ).namespace(
                context, RubyUtil.RUBY.newSymbol(String.format("%ss", pluginType.asJavaString()))
            );
        }
    }
}
