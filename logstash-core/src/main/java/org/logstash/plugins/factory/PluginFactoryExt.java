package org.logstash.plugins.factory;

import co.elastic.logstash.api.*;
import org.jruby.*;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.common.EnvironmentVariableProvider;
import org.logstash.common.SourceWithMetadata;
import org.logstash.config.ir.PipelineIR;
import org.logstash.config.ir.compiler.*;
import org.logstash.config.ir.graph.Vertex;
import org.logstash.execution.ExecutionContextExt;
import org.logstash.instrument.metrics.AbstractMetricExt;
import org.logstash.instrument.metrics.AbstractNamespacedMetricExt;
import org.logstash.instrument.metrics.MetricKeys;
import org.logstash.plugins.ConfigVariableExpander;
import org.logstash.plugins.PluginLookup;

import java.util.*;

@JRubyClass(name = "PluginFactory")
public final class PluginFactoryExt extends RubyBasicObject
    implements RubyIntegration.PluginFactory {

    @FunctionalInterface
    public interface PluginResolver {
        PluginLookup.PluginClass resolve(PluginLookup.PluginType type, String name);
    }

    private static final long serialVersionUID = 1L;

    private static final RubyString ID_KEY = RubyUtil.RUBY.newString("id");

    private final Collection<String> pluginsById = new HashSet<>();

    private PipelineIR lir;

    private ExecutionContextFactoryExt executionContextFactory;

    private PluginMetricsFactoryExt metrics;

    private RubyClass filterClass;

    private ConfigVariableExpander configVariables;

    private PluginResolver pluginResolver;

    private Map<PluginLookup.PluginType, AbstractPluginCreator<? extends Plugin>> pluginCreatorsRegistry = new HashMap<>(4);

    @JRubyMethod(name = "filter_delegator", meta = true, required = 5)
    public static IRubyObject filterDelegator(final ThreadContext context,
                                              final IRubyObject recv, final IRubyObject... args) {
        final RubyHash arguments = (RubyHash) args[2];
        final IRubyObject filterInstance = args[1].callMethod(context, "new", arguments);
        final RubyString id = (RubyString) arguments.op_aref(context, ID_KEY);
        filterInstance.callMethod(
                context, "metric=",
                ((AbstractMetricExt) args[3]).namespace(context, id.intern())
        );
        filterInstance.callMethod(context, "execution_context=", args[4]);
        return new FilterDelegatorExt(context.runtime, RubyUtil.FILTER_DELEGATOR_CLASS)
                .initialize(context, filterInstance, id);
    }

    public PluginFactoryExt(final Ruby runtime, final RubyClass metaClass) {
        this(runtime, metaClass, PluginLookup::lookup);
    }

    PluginFactoryExt(final Ruby runtime, final RubyClass metaClass, PluginResolver pluginResolver) {
        super(runtime, metaClass);
        this.pluginResolver = pluginResolver;
    }

    @JRubyMethod(required = 4)
    public PluginFactoryExt initialize(final ThreadContext context,
                                       final IRubyObject[] args) {
        return init(
                args[0].toJava(PipelineIR.class),
                (PluginMetricsFactoryExt) args[1], (ExecutionContextFactoryExt) args[2],
                (RubyClass) args[3]
        );
    }

    public PluginFactoryExt init(final PipelineIR lir, final PluginMetricsFactoryExt metrics,
                                 final ExecutionContextFactoryExt executionContextFactoryExt,
                                 final RubyClass filterClass) {
        return this.init(lir, metrics, executionContextFactoryExt, filterClass, EnvironmentVariableProvider.defaultProvider());
    }

    PluginFactoryExt init(final PipelineIR lir, final PluginMetricsFactoryExt metrics,
                          final ExecutionContextFactoryExt executionContextFactoryExt,
                          final RubyClass filterClass,
                          final EnvironmentVariableProvider envVars) {
        this.lir = lir;
        this.metrics = metrics;
        this.executionContextFactory = executionContextFactoryExt;
        this.filterClass = filterClass;
        this.pluginCreatorsRegistry.put(PluginLookup.PluginType.INPUT, new InputPluginCreator(this));
        this.pluginCreatorsRegistry.put(PluginLookup.PluginType.CODEC, new CodecPluginCreator());
        this.pluginCreatorsRegistry.put(PluginLookup.PluginType.FILTER, new FilterPluginCreator());
        this.pluginCreatorsRegistry.put(PluginLookup.PluginType.OUTPUT, new OutputPluginCreator(this));
        this.configVariables = ConfigVariableExpander.withoutSecret(envVars);
        return this;
    }

    @SuppressWarnings("unchecked")
    @Override
    public IRubyObject buildInput(final RubyString name, SourceWithMetadata source,
                                  final IRubyObject args, Map<String, Object> pluginArgs) {
        return plugin(
                RubyUtil.RUBY.getCurrentContext(), PluginLookup.PluginType.INPUT, name.asJavaString(),
                source, (Map<String, IRubyObject>) args, pluginArgs
        );
    }

    @SuppressWarnings("unchecked")
    @Override
    public AbstractOutputDelegatorExt buildOutput(final RubyString name, SourceWithMetadata source,
                                                  final IRubyObject args, Map<String, Object> pluginArgs) {
        return (AbstractOutputDelegatorExt) plugin(
                RubyUtil.RUBY.getCurrentContext(), PluginLookup.PluginType.OUTPUT, name.asJavaString(),
                source, (Map<String, IRubyObject>) args, pluginArgs
        );
    }

    @SuppressWarnings("unchecked")
    @Override
    public AbstractFilterDelegatorExt buildFilter(final RubyString name, SourceWithMetadata source,
                                                  final IRubyObject args, Map<String, Object> pluginArgs) {
        return (AbstractFilterDelegatorExt) plugin(
                RubyUtil.RUBY.getCurrentContext(), PluginLookup.PluginType.FILTER, name.asJavaString(),
                source, (Map<String, IRubyObject>) args, pluginArgs
        );
    }

    @SuppressWarnings("unchecked")
    @Override
    public IRubyObject buildCodec(final RubyString name, SourceWithMetadata source, final IRubyObject args,
                                  Map<String, Object> pluginArgs) {
        return plugin(
                RubyUtil.RUBY.getCurrentContext(), PluginLookup.PluginType.CODEC,
                name.asJavaString(), source, (Map<String, IRubyObject>) args, pluginArgs
        );
    }

    @Override
    public Codec buildDefaultCodec(String codecName) {
        return (Codec) JavaUtil.unwrapJavaValue(plugin(
                RubyUtil.RUBY.getCurrentContext(), PluginLookup.PluginType.CODEC,
                codecName, null, Collections.emptyMap(), Collections.emptyMap()
        ));
    }

    @SuppressWarnings("unchecked")
    @JRubyMethod(required = 3, optional = 1)
    public IRubyObject plugin(final ThreadContext context, final IRubyObject[] args) {
        return plugin(
                context,
                PluginLookup.PluginType.valueOf(args[0].asJavaString().toUpperCase(Locale.ENGLISH)),
                args[1].asJavaString(),
                JavaUtil.unwrapIfJavaObject(args[2]),
                args.length > 3 ? (Map<String, IRubyObject>) args[3] : new HashMap<>(),
                null
        );
    }

    @SuppressWarnings("unchecked")
    private IRubyObject plugin(final ThreadContext context, final PluginLookup.PluginType type, final String name,
                               SourceWithMetadata source, final Map<String, IRubyObject> args,
                               Map<String, Object> pluginArgs) {
        final String id = generateOrRetrievePluginId(context, type, name, source);
        pluginsById.add(id);
        final AbstractNamespacedMetricExt typeScopedMetric = metrics.create(context, type.rubyLabel());

        final PluginLookup.PluginClass pluginClass = pluginResolver.resolve(type, name);
        if (pluginClass.language() == PluginLookup.PluginLanguage.RUBY) {

            final Map<String, Object> newArgs = new HashMap<>(args);
            newArgs.put("id", id);
            final RubyClass klass = (RubyClass) pluginClass.klass();
            final ExecutionContextExt executionCntx = executionContextFactory.create(
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
                        filterClass, klass, rubyArgs, typeScopedMetric, executionCntx);
            } else {
                final IRubyObject pluginInstance = klass.callMethod(context, "new", rubyArgs);
                final AbstractNamespacedMetricExt scopedMetric = typeScopedMetric.namespace(context, RubyUtil.RUBY.newSymbol(id));
                scopedMetric.gauge(context, MetricKeys.NAME_KEY, pluginInstance.callMethod(context, "config_name"));
                pluginInstance.callMethod(context, "metric=", scopedMetric);
                pluginInstance.callMethod(context, "execution_context=", executionCntx);
                return pluginInstance;
            }
        } else {
            if (pluginArgs == null) {
                String err = String.format("Cannot start the Java plugin '%s' in the Ruby execution engine." +
                        " The Java execution engine is required to run Java plugins.", name);
                throw new IllegalStateException(err);
            }

            AbstractPluginCreator<? extends Plugin> pluginCreator = pluginCreatorsRegistry.get(type);
            if (pluginCreator == null) {
                throw new IllegalStateException("Unable to create plugin: " + pluginClass.toReadableString());
            }

            Context contextWithMetrics = executionContextFactory.toContext(type, metrics.getRoot(context));
            return pluginCreator.createDelegator(name, pluginArgs, id, typeScopedMetric, pluginClass, contextWithMetrics);
        }
    }

    private String generateOrRetrievePluginId(ThreadContext context, PluginLookup.PluginType type, String name,
                                              SourceWithMetadata source) {
        final String id;
        if (type == PluginLookup.PluginType.CODEC) {
            id = UUID.randomUUID().toString();
        } else {
            String unresolvedId = lir.getGraph().vertices()
                    .filter(v -> v.getSourceWithMetadata() != null
                            && v.getSourceWithMetadata().equalsWithoutText(source))
                    .findFirst()
                    .map(Vertex::getId).orElse(null);
            id = (String) configVariables.expand(unresolvedId);
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
        return id;
    }

    ExecutionContextFactoryExt getExecutionContextFactory() {
        return executionContextFactory;
    }
}
