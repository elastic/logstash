package org.logstash.config.ir;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Objects;
import java.util.stream.Collectors;
import org.jruby.RubyHash;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.Rubyfier;
import org.logstash.common.SourceWithMetadata;
import org.logstash.config.ir.compiler.Dataset;
import org.logstash.config.ir.compiler.EventCondition;
import org.logstash.config.ir.compiler.RubyIntegration;
import org.logstash.config.ir.graph.IfVertex;
import org.logstash.config.ir.graph.PluginVertex;
import org.logstash.config.ir.graph.Vertex;
import org.logstash.config.ir.imperative.PluginStatement;
import org.logstash.ext.JrubyEventExtLibrary;

/**
 * <h3>Compiled Logstash Pipeline Configuration.</h3>
 * This class represents an executable pipeline, compiled from the configured topology that is
 * learnt from {@link PipelineIR}.
 * Each compiled pipeline consists in graph of {@link Dataset} that represent either a {@code filter}
 * or an {@code if} condition.
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
     * Compiled {@link IfVertex, indexed by their ID as returned by {@link Vertex#getId()}.
     */
    private final Map<String, Dataset.SplitDataset> iffs = new HashMap<>(5);

    /**
     * Cached {@link Dataset} compiled from {@link PluginVertex} indexed by their ID as returned
     * by {@link Vertex#getId()} to avoid duplicate computations.
     */
    private final Map<String, Dataset> plugins = new HashMap<>(5);

    /**
     * Immutable collection of filters that flush on shutdown.
     */
    private final Collection<RubyIntegration.Filter> shutdownFlushes;

    /**
     * Immutable collection of filters that flush periodically.
     */
    private final Collection<RubyIntegration.Filter> periodicFlushes;

    /**
     * Configured outputs.
     */
    private final Map<String, RubyIntegration.Output> outputs;

    /**
     * Parsed pipeline configuration graph.
     */
    private final PipelineIR graph;

    /**
     * Ruby pipeline object.
     */
    private final RubyIntegration.Pipeline pipeline;

    public CompiledPipeline(final PipelineIR graph, final RubyIntegration.Pipeline pipeline) {
        this.graph = graph;
        this.pipeline = pipeline;
        inputs = setupInputs();
        filters = setupFilters();
        outputs = setupOutputs();
        shutdownFlushes = Collections.unmodifiableList(
            filters.values().stream().filter(RubyIntegration.Filter::hasFlush)
                .collect(Collectors.toList())
        );
        periodicFlushes = Collections.unmodifiableList(
            shutdownFlushes.stream().filter(RubyIntegration.Filter::periodicFlush)
                .collect(Collectors.toList())
        );
    }

    public Collection<RubyIntegration.Filter> shutdownFlushers() {
        return shutdownFlushes;
    }

    public Collection<RubyIntegration.Filter> periodicFlushers() {
        return periodicFlushes;
    }

    public Collection<RubyIntegration.Output> outputs() {
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
    public Dataset buildFilterFunc() {
        return compilePipeline(false);
    }

    /**
     * This method contains the actual compilation of the {@link Dataset} representing the
     * underlying pipeline from the Queue to the outputs as a Debug pipeline.
     * This means that it will return all {@link JrubyEventExtLibrary.RubyEvent} that passed through
     * it from its terminal {@link Dataset} by using
     * {@link Dataset.TerminalDataset.TerminalDebugDataset}.
     * @return Compiled {@link Dataset} representation of the underlying {@link PipelineIR} topology
     */
    public Dataset buildFilterFuncDebug() {
        return compilePipeline(true);
    }

    /**
     * This method contains the actual compilation of the {@link Dataset} representing the
     * underlying pipeline from the Queue to the outputs.
     * @param debug True iff called from {@link CompiledPipeline#buildFilterFuncDebug()} to
     * terminate on a {@link Dataset.TerminalDataset.TerminalDebugDataset}
     */
    private Dataset compilePipeline(final boolean debug) {
        final Collection<Dataset> datasets = new ArrayList<>(5);
        // We sort the leaves of the graph in a deterministic fashion before compilation.
        // This is not strictly necessary for correctness since it will only influence the order
        // of output events for which Logstash makes no guarantees, but it greatly simplifies
        // testing and is no issue performance wise since compilation only happens on pipeline
        // reload.
        iffs.clear();
        plugins.clear();
        graph.getGraph().getAllLeaves().stream().sorted(Comparator.comparing(Vertex::hashPrefix))
            .forEachOrdered(
                leaf -> {
                    final Collection<Dataset> parents =
                        flatten(Dataset.ROOT_DATASETS, leaf);
                    if (isFilter(leaf)) {
                        datasets.add(filterDataset(leaf.getId(), parents));
                    } else if (leaf instanceof IfVertex) {
                        datasets.add(
                            splitRight(parents, buildCondition((IfVertex) leaf), leaf.getId())
                        );
                    } else if (isOutput(leaf)) {
                        datasets.add(outputDataset(leaf.getId(), parents));
                    } else {
                        datasets.addAll(parents);
                    }
                }
            );
        return Dataset.TerminalDataset.from(datasets, debug);
    }

    /**
     * Sets up all Ruby outputs learnt from {@link PipelineIR}.
     */
    private Map<String, RubyIntegration.Output> setupOutputs() {
        final Collection<PluginVertex> outs = graph.getOutputPluginVertices();
        final Map<String, RubyIntegration.Output> res = new HashMap<>(outs.size());
        outs.forEach(v -> {
            final PluginDefinition def = v.getPluginDefinition();
            final SourceWithMetadata source = v.getSourceWithMetadata();
            res.put(v.getId(), pipeline.buildOutput(
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
        final Collection<PluginVertex> plugins = graph.getFilterPluginVertices();
        final Map<String, RubyIntegration.Filter> res = new HashMap<>(plugins.size());
        for (final PluginVertex plugin : plugins) {
            final String ident = plugin.getId();
            if (!res.containsKey(ident)) {
                res.put(ident, buildFilter(plugin));
            }
        }
        return res;
    }

    /**
     * Sets up all Ruby inputs learnt from {@link PipelineIR}.
     */
    private Collection<IRubyObject> setupInputs() {
        final Collection<PluginVertex> vertices = graph.getInputPluginVertices();
        final Collection<IRubyObject> nodes = new HashSet<>(vertices.size());
        vertices.forEach(v -> {
            final PluginDefinition def = v.getPluginDefinition();
            final SourceWithMetadata source = v.getSourceWithMetadata();
            nodes.add(pipeline.buildInput(
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
     * @return RubyHash of plugin arguments as understood by {@link RubyIntegration.Pipeline}
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
                toput = pipeline.buildCodec(
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
        return pipeline.buildFilter(
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
     * Checks if a certain {@link Vertex} represents a {@link RubyIntegration.Output}.
     * @param vertex Vertex to check
     * @return True iff {@link Vertex} represents a {@link RubyIntegration.Output}
     */
    private boolean isOutput(final Vertex vertex) {
        return outputs.containsKey(vertex.getId());
    }

    /**
     * Compiles the next level of the execution from the given {@link Vertex} or simply return
     * the given {@link Dataset} at the previous level if the starting {@link Vertex} cannot
     * be expanded any further (i.e. doesn't have any more incoming vertices that are either
     * a {code filter} or and {code if} statement).
     * @param parents Nodes from the last already compiled level
     * @param start Vertex to compile children for
     * @return Datasets originating from given {@link Vertex}
     */
    private Collection<Dataset> flatten(final Collection<Dataset> parents, final Vertex start) {
        final Collection<Vertex> endings = start.incomingVertices()
            .filter(v -> isFilter(v) || isOutput(v) || v instanceof IfVertex)
            .collect(Collectors.toList());
        return endings.isEmpty() ? parents : flattenChildren(parents, start, endings);
    }

    /**
     * Compiles all child vertices for a given vertex.
     * @param parents Parent datasets from previous stage
     * @param start Start Vertex that got expanded
     * @param children Children of {@code start} that are either {@code if} or {@code filter} in
     * type
     * @return Datasets compiled from vertex children
     */
    private Collection<Dataset> flattenChildren(final Collection<Dataset> parents,
        final Vertex start, final Collection<Vertex> children) {
        return children.stream().map(
            child -> {
                final Collection<Dataset> newparents = flatten(parents, child);
                if (isFilter(child)) {
                    return filterDataset(child.getId(), newparents);
                } else if (isOutput(child)) {
                    return outputDataset(child.getId(), newparents);
                } else {
                    // We know that it's an if vertex since the the input children are either 
                    // output, filter or if in type.
                    final IfVertex ifvert = (IfVertex) child;
                    final EventCondition iff = buildCondition(ifvert);
                    final String index = ifvert.getId();
                    // It is important that we double check that we are actually dealing with the
                    // positive/left branch of the if condition
                    if (ifvert.getOutgoingBooleanEdgesByType(true).stream()
                        .anyMatch(edge -> Objects.equals(edge.getTo(), start))) {
                        return splitLeft(newparents, iff, index);
                    } else {
                        return splitRight(newparents, iff, index);
                    }
                }
            }).collect(Collectors.toList());
    }

    /**
     * Build a {@link Dataset} representing the {@link JrubyEventExtLibrary.RubyEvent}s after
     * the application of the given filter.
     * @param vertex Vertex Id of the filter to create this {@link Dataset} for
     * @param parents All the parent nodes that go into this filter
     * @return Filter {@link Dataset}
     */
    private Dataset filterDataset(final String vertex, final Collection<Dataset> parents) {
        final Dataset filter;
        if (plugins.containsKey(vertex)) {
            filter = plugins.get(vertex);
        } else {
            final RubyIntegration.Filter ruby = filters.get(vertex);
            if (ruby.hasFlush()) {
                if (ruby.periodicFlush()) {
                    filter = new Dataset.FilteredFlushableDataset(parents, ruby);
                } else {
                    filter = new Dataset.FilteredShutdownFlushableDataset(parents, ruby);
                }
            } else {
                filter = new Dataset.FilteredDataset(parents, ruby);
            }
            plugins.put(vertex, filter);
        }
        return filter;
    }

    /**
     * Build a {@link Dataset} representing the {@link JrubyEventExtLibrary.RubyEvent}s after
     * the application of the given output.
     * @param vertex Vertex Id of the filter to create this {@link Dataset} for
     * filter node in the topology once
     * @param parents All the parent nodes that go into this output
     * @return Output {@link Dataset}
     */
    private Dataset outputDataset(final String vertex, final Collection<Dataset> parents) {
        final Dataset output;
        if (plugins.containsKey(vertex)) {
            output = plugins.get(vertex);
        } else {
            final RubyIntegration.Output ruby = outputs.get(vertex);
            output = new Dataset.OutputDataset(parents, ruby);
            plugins.put(vertex, output);
        }
        return output;
    }

    /**
     * Split the parent {@link Dataset}s and return the dataset half of their elements that contains
     * the {@link JrubyEventExtLibrary.RubyEvent} that <strong>do not</strong> fulfil the given
     * {@link EventCondition}.
     * @param parents Datasets to split
     * @param condition Condition that must be not be fulfilled
     * @param index Vertex id to cache the resulting {@link Dataset} under
     * @return The half of the datasets contents that does not fulfil the condition
     */
    private Dataset splitRight(final Collection<Dataset> parents,
        final EventCondition condition, final String index) {
        return splitLeft(parents, condition, index).right();
    }

    /**
     * Split the parent {@link Dataset}s and return the dataset half of their elements that contains
     * the {@link JrubyEventExtLibrary.RubyEvent} that fulfil the given {@link EventCondition}.
     * @param parents Datasets to split
     * @param condition Condition that must be fulfilled
     * @param index Vertex id to cache the resulting {@link Dataset} under
     * @return The half of the datasets contents that fulfils the condition
     */
    private Dataset.SplitDataset splitLeft(final Collection<Dataset> parents,
        final EventCondition condition, final String index) {
        if (!iffs.containsKey(index)) {
            iffs.put(index, new Dataset.SplitDataset(parents, condition));
        }
        return iffs.get(index);
    }

    /**
     * Compiles an {@link IfVertex} into an {@link EventCondition}.
     * @param iff IfVertex to build condition for
     * @return EventCondition for given {@link IfVertex}
     */
    private static EventCondition buildCondition(final IfVertex iff) {
        return EventCondition.Compiler.buildCondition(iff.getBooleanExpression());
    }

}
