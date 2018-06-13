package org.logstash.plugins;

import java.util.Arrays;
import java.util.Collection;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;
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
import org.logstash.config.ir.compiler.FilterDelegatorExt;
import org.logstash.config.ir.compiler.OutputDelegatorExt;
import org.logstash.config.ir.compiler.OutputStrategyExt;
import org.logstash.config.ir.compiler.RubyIntegration;
import org.logstash.config.ir.graph.Vertex;
import org.logstash.execution.ExecutionContextExt;
import org.logstash.instrument.metrics.AbstractMetricExt;
import org.logstash.instrument.metrics.AbstractNamespacedMetricExt;
import org.logstash.instrument.metrics.NullMetricExt;

public final class PluginFactoryExt {

    @JRubyClass(name = "PluginFactory")
    public static final class Plugins extends RubyBasicObject
        implements RubyIntegration.PluginFactory {

        private static final RubyString ID_KEY = RubyUtil.RUBY.newString("id");

        private static final RubySymbol NAME_KEY = RubyUtil.RUBY.newSymbol("name");

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
                args[3].callMethod(context, "namespace", id.intern19())
            );
            filterInstance.callMethod(context, "execution_context=", args[4]);
            return args[0].callMethod(context, "new", new IRubyObject[]{filterInstance, id});
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
        public OutputDelegatorExt buildOutput(final RubyString name, final RubyInteger line,
            final RubyInteger column, final IRubyObject args) {
            return (OutputDelegatorExt) plugin(
                RubyUtil.RUBY.getCurrentContext(), PluginLookup.PluginType.OUTPUT,
                name.asJavaString(), line.getIntValue(), column.getIntValue(),
                (Map<String, IRubyObject>) args
            );
        }

        @JRubyMethod(required = 4)
        public OutputDelegatorExt buildOutput(final ThreadContext context,
            final IRubyObject[] args) {
            return buildOutput(
                (RubyString) args[0], args[1].convertToInteger(), args[2].convertToInteger(), args[3]
            );
        }

        @SuppressWarnings("unchecked")
        @Override
        public FilterDelegatorExt buildFilter(final RubyString name, final RubyInteger line,
            final RubyInteger column, final IRubyObject args) {
            return (FilterDelegatorExt) plugin(
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
            final AbstractNamespacedMetricExt typeScopedMetric =
                metrics.create(context, type.rubyLabel());
            final PluginLookup.PluginClass pluginClass = PluginLookup.lookup(type, name);
            if (pluginClass.language() == PluginLookup.PluginLanguage.RUBY) {
                final Map<String, Object> newArgs = new HashMap<>(args);
                newArgs.put("id", id);
                final RubyClass klass = (RubyClass) pluginClass.klass();
                final ExecutionContextExt executionCntx = executionContext.create(
                    context, RubyUtil.RUBY.newString(id), klass.callMethod(context, "config_name")
                );
                final RubyHash rubyArgs = RubyHash.newHash(context.runtime);
                rubyArgs.putAll(newArgs);
                if (type == PluginLookup.PluginType.OUTPUT) {
                    return new OutputDelegatorExt(context.runtime, RubyUtil.OUTPUT_DELEGATOR_CLASS).init(
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
                    scopedMetric.gauge(context, NAME_KEY, pluginInstance.callMethod(context, "config_name"));
                    pluginInstance.callMethod(context, "metric=", scopedMetric);
                    pluginInstance.callMethod(context, "execution_context=", executionCntx);
                    return pluginInstance;
                }
            } else {
                return context.nil;
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
