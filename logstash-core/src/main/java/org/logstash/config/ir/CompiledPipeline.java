package org.logstash.config.ir;

import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.stream.Collectors;
import org.jruby.RubyHash;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.Rubyfier;
import org.logstash.common.SourceWithMetadata;
import org.logstash.config.ir.compiler.Dataset;
import org.logstash.config.ir.compiler.DatasetCompiler;
import org.logstash.config.ir.compiler.EventCondition;
import org.logstash.config.ir.compiler.RubyIntegration;
import org.logstash.config.ir.compiler.SplitDataset;
import org.logstash.config.ir.graph.IfVertex;
import org.logstash.config.ir.graph.PluginVertex;
import org.logstash.config.ir.graph.Vertex;
import org.logstash.config.ir.imperative.PluginStatement;
import org.logstash.ext.JrubyEventExtLibrary;

/**
 * <h3>Compiled Logstash Pipeline Configuration.</h3>
 * This class represents an executable pipeline, compiled from the configured topology that is
 * learnt from {@link PipelineIR}.
 * Each compiled pipeline consists in graph of {@link Dataset} that represent either a
 * {@code filter}, {@code output} or an {@code if} condition.
 */
public final class CompiledPipeline {

    /**
     * Configured inputs.
     */
    private final Collection<IRubyObject> inputs;

    /**
     * Configured Filters, indexed by their ID as returned by {@link PluginVertex#getId()}.
     */
    private final Map<String, RubyIntegration.Filter> filters;

    /**
     * Configured outputs.
     */
    private final Map<String, IRubyObject> outputs;

    /**
     * Parsed pipeline configuration graph.
     */
    private final PipelineIR pipelineIR;

    /**
     * Ruby plugin factory instance.
     */
    private final RubyIntegration.PluginFactory pluginFactory;

    public CompiledPipeline(final PipelineIR pipelineIR,
        final RubyIntegration.PluginFactory pluginFactory) {
        this.pipelineIR = pipelineIR;
        this.pluginFactory = pluginFactory;
        inputs = setupInputs();
        filters = setupFilters();
        outputs = setupOutputs();
    }

    public Collection<IRubyObject> outputs() {
        return Collections.unmodifiableCollection(outputs.values());
    }

    public Collection<RubyIntegration.Filter> filters() {
        return Collections.unmodifiableCollection(filters.values());
    }

    public Collection<IRubyObject> inputs() {
        return inputs;
    }

    public RubyIntegration.Plugin registerPlugin(final RubyIntegration.Plugin plugin) {
        plugin.register();
        return plugin;
    }

    /**
     * This method contains the actual compilation of the {@link Dataset} representing the
     * underlying pipeline from the Queue to the outputs.
     * @return Compiled {@link Dataset} representation of the underlying {@link PipelineIR} topology
     */
    public Dataset buildExecution() {
        return new CompiledPipeline.CompiledExecution().toDataset();
    }

    /**
     * Get the generated source
     * @return sorted and formatted lines of generated code
     */
    public List<String> getGeneratedSource(){
        return DatasetCompiler.getGeneratedSource();
    }

    /**
     * Sets up all Ruby outputs learnt from {@link PipelineIR}.
     */
    private Map<String, IRubyObject> setupOutputs() {
        final Collection<PluginVertex> outs = pipelineIR.getOutputPluginVertices();
        final Map<String, IRubyObject> res = new HashMap<>(outs.size());
        outs.forEach(v -> {
            final PluginDefinition def = v.getPluginDefinition();
            final SourceWithMetadata source = v.getSourceWithMetadata();
            res.put(v.getId(), pluginFactory.buildOutput(
                RubyUtil.RUBY.newString(def.getName()), RubyUtil.RUBY.newFixnum(source.getLine()),
                RubyUtil.RUBY.newFixnum(source.getColumn()), convertArgs(def)
            ));
        });
        return res;
    }

    /**
     * Sets up all Ruby filters learnt from {@link PipelineIR}.
     */
    private Map<String, RubyIntegration.Filter> setupFilters() {
        final Collection<PluginVertex> filterPlugins = pipelineIR.getFilterPluginVertices();
        final Map<String, RubyIntegration.Filter> res =
            new HashMap<>(filterPlugins.size(), 1.0F);
        for (final PluginVertex plugin : filterPlugins) {
            res.put(plugin.getId(), buildFilter(plugin));
        }
        return res;
    }

    /**
     * Sets up all Ruby inputs learnt from {@link PipelineIR}.
     */
    private Collection<IRubyObject> setupInputs() {
        final Collection<PluginVertex> vertices = pipelineIR.getInputPluginVertices();
        final Collection<IRubyObject> nodes = new HashSet<>(vertices.size());
        vertices.forEach(v -> {
            final PluginDefinition def = v.getPluginDefinition();
            final SourceWithMetadata source = v.getSourceWithMetadata();
            nodes.add(pluginFactory.buildInput(
                RubyUtil.RUBY.newString(def.getName()), RubyUtil.RUBY.newFixnum(source.getLine()),
                RubyUtil.RUBY.newFixnum(source.getColumn()), convertArgs(def)
            ));
        });
        return nodes;
    }

    /**
     * Converts plugin arguments from the format provided by {@link PipelineIR} into coercible
     * Ruby types.
     * @param def PluginDefinition as provided by {@link PipelineIR}
     * @return RubyHash of plugin arguments as understood by {@link RubyIntegration.PluginFactory}
     * methods
     */
    private RubyHash convertArgs(final PluginDefinition def) {
        final RubyHash converted = RubyHash.newHash(RubyUtil.RUBY);
        for (final Map.Entry<String, Object> entry : def.getArguments().entrySet()) {
            final Object value = entry.getValue();
            final String key = entry.getKey();
            final Object toput;
            if (value instanceof PluginStatement) {
                final PluginDefinition codec = ((PluginStatement) value).getPluginDefinition();
                toput = pluginFactory.buildCodec(
                    RubyUtil.RUBY.newString(codec.getName()),
                    Rubyfier.deep(RubyUtil.RUBY, codec.getArguments())
                );
            } else {
                toput = value;
            }
            converted.put(key, toput);
        }
        return converted;
    }

    /**
     * Compiles a {@link RubyIntegration.Filter} from a given {@link PluginVertex}.
     * @param vertex Filter {@link PluginVertex}
     * @return Compiled {@link RubyIntegration.Filter}
     */
    private RubyIntegration.Filter buildFilter(final PluginVertex vertex) {
        final PluginDefinition def = vertex.getPluginDefinition();
        final SourceWithMetadata source = vertex.getSourceWithMetadata();
        return pluginFactory.buildFilter(
            RubyUtil.RUBY.newString(def.getName()), RubyUtil.RUBY.newFixnum(source.getLine()),
            RubyUtil.RUBY.newFixnum(source.getColumn()), convertArgs(def)
        );
    }

    /**
     * Checks if a certain {@link Vertex} represents a {@link RubyIntegration.Filter}.
     * @param vertex Vertex to check
     * @return True iff {@link Vertex} represents a {@link RubyIntegration.Filter}
     */
    private boolean isFilter(final Vertex vertex) {
        return filters.containsKey(vertex.getId());
    }

    /**
     * Checks if a certain {@link Vertex} represents an output.
     * @param vertex Vertex to check
     * @return True iff {@link Vertex} represents an output
     */
    private boolean isOutput(final Vertex vertex) {
        return outputs.containsKey(vertex.getId());
    }

    /**
     * Instances of this class represent a fully compiled pipeline execution. Note that this class
     * has a separate lifecycle from {@link CompiledPipeline} because it holds per (worker-thread)
     * state and thus needs to be instantiated once per thread.
     */
    private final class CompiledExecution {

        /**
         * Compiled {@link IfVertex, indexed by their ID as returned by {@link Vertex#getId()}.
         */
        private final Map<String, SplitDataset> iffs = new HashMap<>(5);

        /**
         * Cached {@link Dataset} compiled from {@link PluginVertex} indexed by their ID as returned
         * by {@link Vertex#getId()} to avoid duplicate computations.
         */
        private final Map<String, Dataset> plugins = new HashMap<>(5);

        private final Dataset compiled;

        CompiledExecution() {
            compiled = compile();
        }

        Dataset toDataset() {
            return compiled;
        }

        /**
         * Instantiates the graph of compiled {@link Dataset}.
         * @return Compiled {@link Dataset} representing the pipeline.
         */
        private Dataset compile() {
            final Collection<Vertex> outputs = pipelineIR.getGraph()
                .allLeaves().filter(CompiledPipeline.this::isOutput)
                .collect(Collectors.toList());
            if (outputs.isEmpty()) {
                return DatasetCompiler.ROOT_DATASETS.iterator().next();
            } else {
                return DatasetCompiler.terminalDataset(outputs.stream().map(
                    leaf ->
                        outputDataset(leaf.getId(), getConfigSource(leaf), flatten(DatasetCompiler.ROOT_DATASETS, leaf))
                ).collect(Collectors.toList()));
            }
        }

        /**
         * Build a {@link Dataset} representing the {@link JrubyEventExtLibrary.RubyEvent}s after
         * the application of the given filter.
         * @param vertexId Vertex Id of the filter to create this {@link Dataset}
         * @param configSource The Logstash configuration that maps to the returned Dataset
         * @param datasets All the datasets that pass through this filter
         * @return Filter {@link Dataset}
         */
        private Dataset filterDataset(final String vertexId, String configSource, final Collection<Dataset> datasets) {
            return plugins.computeIfAbsent(
                vertexId, v -> DatasetCompiler.filterDataset(datasets, filters.get(v), configSource)
            );
        }

        /**
         * Build a {@link Dataset} representing the {@link JrubyEventExtLibrary.RubyEvent}s after
         * the application of the given output.
         * @param vertexId Vertex Id of the filter to create this {@link Dataset} for
         * filter node in the topology once
         * @param configSource The Logstash configuration that maps to the returned Dataset
         * @param datasets All the datasets that are passed into this output
         * @return Output {@link Dataset}
         */
        private Dataset outputDataset(final String vertexId, String configSource, final Collection<Dataset> datasets) {
            return plugins.computeIfAbsent(
                vertexId, v -> DatasetCompiler.outputDataset(
                    datasets, outputs.get(v), configSource, outputs.size() == 1
                )
            );
        }

        /**
         * Split the given {@link Dataset}s and return the dataset half of their elements that contains
         * the {@link JrubyEventExtLibrary.RubyEvent} that fulfil the given {@link EventCondition}.
         * @param datasets Datasets to split
         * @param condition Condition that must be fulfilled
         * @param index Vertex id to cache the resulting {@link Dataset} under
         * @param configSource The Logstash configuration that maps to the returned Dataset
         * @return The half of the datasets contents that fulfils the condition
         */
        private SplitDataset split(final Collection<Dataset> datasets,
            final EventCondition condition, final String index, String configSource) {
            return iffs.computeIfAbsent(
                index, ind -> DatasetCompiler.splitDataset(datasets, condition, configSource)
            );
        }

        /**
         * Compiles the next level of the execution from the given {@link Vertex} or simply return
         * the given {@link Dataset} at the previous level if the starting {@link Vertex} cannot
         * be expanded any further (i.e. doesn't have any more incoming vertices that are either
         * a {code filter} or and {code if} statement).
         * @param datasets Nodes from the last already compiled level
         * @param start Vertex to compile children for
         * @return Datasets originating from given {@link Vertex}
         */
        private Collection<Dataset> flatten(final Collection<Dataset> datasets,
            final Vertex start) {
            final Collection<Vertex> dependencies = start.incomingVertices()
                .filter(v -> isFilter(v) || isOutput(v) || v instanceof IfVertex)
                .collect(Collectors.toList());
            return dependencies.isEmpty() ? datasets
                : compileDependencies(start, datasets, dependencies);
        }

        /**
         * Compiles all child vertices for a given vertex.
         * @param datasets Datasets from previous stage
         * @param start Start Vertex that got expanded
         * @param dependencies Dependencies of {@code start}
         * @return Datasets compiled from vertex children
         */
        private Collection<Dataset> compileDependencies(final Vertex start,
            final Collection<Dataset> datasets, final Collection<Vertex> dependencies) {
            return dependencies.stream().map(
                dependency -> {
                    final Collection<Dataset> transientDependencies = flatten(datasets, dependency);
                    final String id = dependency.getId();
                    if (isFilter(dependency)) {
                        return filterDataset(id, getConfigSource(dependency), transientDependencies);
                    } else if (isOutput(dependency)) {
                        return outputDataset(id, getConfigSource(dependency), transientDependencies);
                    } else {
                        // We know that it's an if vertex since the the input children are either
                        // output, filter or if in type.
                        final IfVertex ifvert = (IfVertex) dependency;
                        final SplitDataset ifDataset = split(
                            transientDependencies,
                            EventCondition.Compiler.buildCondition(ifvert.getBooleanExpression()),
                            id, getConfigSource(dependency)
                        );
                        // It is important that we double check that we are actually dealing with the
                        // positive/left branch of the if condition
                        if (ifvert.getOutgoingBooleanEdgesByType(true).stream()
                            .anyMatch(edge -> Objects.equals(edge.getTo(), start))) {
                            return ifDataset;
                        } else {
                            return ifDataset.right();
                        }
                    }
                }).collect(Collectors.toList());
        }
    }

    /**
     * Gets the configuration source for debugging purposes. Uses the metadata text if it exists, else the vertex toString method
     * @param vertex The {@link Vertex} to read the Logstash configuration source
     * @return A String that can be useful for debugging the Logstash configuration to generated Dataset/code
     */
    private String getConfigSource(Vertex vertex){
        if( vertex == null){
            return "(vertex is null, this is likely a bug)";
        }
        //conditionals will use this
        if(vertex.getSourceWithMetadata() == null){
            return vertex.toString();
        }
        String text  = vertex.getSourceWithMetadata().getText();
        return text == null ? "(vertex.getSourceWithMetadata().getText() is null, this is likely a bug)" : text;
    }
}
