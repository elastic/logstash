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

package org.logstash.config.ir;

import org.jruby.RubyArray;
import org.jruby.RubyHash;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.Rubyfier;
import org.logstash.common.EnvironmentVariableProvider;
import org.logstash.common.SourceWithMetadata;
import org.logstash.config.ir.compiler.AbstractFilterDelegatorExt;
import org.logstash.config.ir.compiler.AbstractOutputDelegatorExt;
import org.logstash.config.ir.compiler.ComputeStepSyntaxElement;
import org.logstash.config.ir.compiler.Dataset;
import org.logstash.config.ir.compiler.DatasetCompiler;
import org.logstash.config.ir.compiler.EventCondition;
import org.logstash.config.ir.compiler.RubyIntegration;
import org.logstash.config.ir.compiler.SplitDataset;
import org.logstash.config.ir.graph.SeparatorVertex;
import org.logstash.config.ir.graph.IfVertex;
import org.logstash.config.ir.graph.PluginVertex;
import org.logstash.config.ir.graph.Vertex;
import org.logstash.config.ir.imperative.PluginStatement;
import org.logstash.execution.QueueBatch;
import org.logstash.ext.JrubyEventExtLibrary.RubyEvent;
import org.logstash.plugins.ConfigVariableExpander;
import org.logstash.secret.store.SecretStore;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import static org.logstash.config.ir.compiler.Utils.copyNonCancelledEvents;

/**
 * <h2>Compiled Logstash Pipeline Configuration.</h2>
 * This class represents an executable pipeline, compiled from the configured topology that is
 * learnt from {@link PipelineIR}.
 * Each compiled pipeline consists in graph of {@link Dataset} that represent either a
 * {@code filter}, {@code output} or an {@code if} condition.
 */
public final class CompiledPipeline {

    /**
     * Compiler for conditional expressions that turn {@link IfVertex} into {@link EventCondition}.
     */
    private final EventCondition.Compiler conditionalCompiler = new EventCondition.Compiler();

    /**
     * Configured inputs.
     */
    private final Collection<IRubyObject> inputs;

    /**
     * Configured Filters, indexed by their ID as returned by {@link PluginVertex#getId()}.
     */
    private final Map<String, AbstractFilterDelegatorExt> filters;

    /**
     * Configured outputs.
     */
    private final Map<String, AbstractOutputDelegatorExt> outputs;

    /**
     * Parsed pipeline configuration graph.
     */
    private final PipelineIR pipelineIR;

    /**
     * Ruby plugin factory instance.
     */
    private final RubyIntegration.PluginFactory pluginFactory;

    public CompiledPipeline(
            final PipelineIR pipelineIR,
            final RubyIntegration.PluginFactory pluginFactory)
    {
        this(pipelineIR, pluginFactory, null);
    }

    public CompiledPipeline(
            final PipelineIR pipelineIR,
            final RubyIntegration.PluginFactory pluginFactory,
            final SecretStore secretStore)
    {
        this.pipelineIR = pipelineIR;
        this.pluginFactory = pluginFactory;
        try (ConfigVariableExpander cve = new ConfigVariableExpander(
                secretStore,
                EnvironmentVariableProvider.defaultProvider())) {
            inputs = setupInputs(cve);
            filters = setupFilters(cve);
            outputs = setupOutputs(cve);
        } catch (Exception e) {
            throw new IllegalStateException("Unable to configure plugins: " + e.getMessage(), e);
        }
    }

    public Collection<AbstractOutputDelegatorExt> outputs() {
        return Collections.unmodifiableCollection(outputs.values());
    }

    public Collection<AbstractFilterDelegatorExt> filters() {
        return Collections.unmodifiableCollection(filters.values());
    }

    public Collection<IRubyObject> inputs() {
        return Collections.unmodifiableCollection(inputs);
    }

    /**
     * Perform the actual compilation of the {@link Dataset} representing the
     * underlying pipeline from the Queue to the outputs using the
     * unordered  execution model.
     * @return CompiledPipeline.CompiledExecution the compiled pipeline
     */
    public CompiledPipeline.CompiledExecution buildExecution() {
        return buildExecution(false);
    }

    /**
     * Perform the actual compilation of the {@link Dataset} representing the
     * underlying pipeline from the Queue to the outputs using the ordered or
     * unordered  execution model.
     * @param orderedExecution determines whether to build an execution that enforces order or not
     * @return CompiledPipeline.CompiledExecution the compiled pipeline
     */
    public CompiledPipeline.CompiledExecution buildExecution(boolean orderedExecution) {
        return orderedExecution
            ? new CompiledPipeline.CompiledOrderedExecution()
            : new CompiledPipeline.CompiledUnorderedExecution();
    }

    /**
     * Sets up all outputs learned from {@link PipelineIR}.
     */
    private Map<String, AbstractOutputDelegatorExt> setupOutputs(ConfigVariableExpander cve) {
        final Collection<PluginVertex> outs = pipelineIR.getOutputPluginVertices();
        final Map<String, AbstractOutputDelegatorExt> res = new HashMap<>(outs.size());
        outs.forEach(v -> {
            final PluginDefinition def = v.getPluginDefinition();
            final SourceWithMetadata source = v.getSourceWithMetadata();
            final Map<String, Object> args = expandArguments(def, cve);
            res.put(v.getId(), pluginFactory.buildOutput(
                RubyUtil.RUBY.newString(def.getName()), convertArgs(args), source
            ));
        });
        return res;
    }

    /**
     * Sets up all Ruby filters learnt from {@link PipelineIR}.
     */
    private Map<String, AbstractFilterDelegatorExt> setupFilters(ConfigVariableExpander cve) {
        final Collection<PluginVertex> filterPlugins = pipelineIR.getFilterPluginVertices();
        final Map<String, AbstractFilterDelegatorExt> res = new HashMap<>(filterPlugins.size(), 1.0F);

        for (final PluginVertex vertex : filterPlugins) {
            final PluginDefinition def = vertex.getPluginDefinition();
            final SourceWithMetadata source = vertex.getSourceWithMetadata();
            final Map<String, Object> args = expandArguments(def, cve);
            res.put(vertex.getId(), pluginFactory.buildFilter(
                RubyUtil.RUBY.newString(def.getName()), convertArgs(args), source
            ));
        }
        return res;
    }

    /**
     * Sets up all Ruby inputs learnt from {@link PipelineIR}.
     */
    private Collection<IRubyObject> setupInputs(ConfigVariableExpander cve) {
        final Collection<PluginVertex> vertices = pipelineIR.getInputPluginVertices();
        final Collection<IRubyObject> nodes = new HashSet<>(vertices.size());
        vertices.forEach(v -> {
            final PluginDefinition def = v.getPluginDefinition();
            final SourceWithMetadata source = v.getSourceWithMetadata();
            final Map<String, Object> args = expandArguments(def, cve);
            IRubyObject o = pluginFactory.buildInput(
                RubyUtil.RUBY.newString(def.getName()), convertArgs(args), source);
            nodes.add(o);
        });
        return nodes;
    }

    final RubyHash convertArgs(final Map<String, Object> input) {
        final RubyHash converted = RubyHash.newHash(RubyUtil.RUBY);
        for (final Map.Entry<String, Object> entry : input.entrySet()) {
            final Object value = entry.getValue();
            final String key = entry.getKey();
            converted.put(key, value);
        }

        return converted;
    }


    private Map<String, Object> expandArguments(final PluginDefinition pluginDefinition, final ConfigVariableExpander cve) {
        Map<String, Object> arguments = expandConfigVariables(cve, pluginDefinition.getArguments());

        // Intercept codec definitions from LIR
        for (final Map.Entry<String, Object> entry : arguments.entrySet()) {
            final String key = entry.getKey();
            final Object value = entry.getValue();
            if (value instanceof PluginStatement) {
                final PluginStatement codecPluginStatement = (PluginStatement) value;
                final PluginDefinition codecDefinition = codecPluginStatement.getPluginDefinition();
                final SourceWithMetadata codecSource = codecPluginStatement.getSourceWithMetadata();
                final Map<String, Object> codecArguments = expandArguments(codecDefinition, cve);
                IRubyObject codecInstance = pluginFactory.buildCodec(RubyUtil.RUBY.newString(codecDefinition.getName()),
                        Rubyfier.deep(RubyUtil.RUBY, codecArguments),
                        codecSource);
                arguments.put(key, codecInstance);
            }
        }

        return arguments;
    }

    @SuppressWarnings({"rawtypes", "unchecked"})
    public static Map<String, Object> expandConfigVariables(ConfigVariableExpander cve, Map<String, Object> configArgs, boolean keepSecrets) {
        Map<String, Object> expandedConfig = new HashMap<>();
        for (Map.Entry<String, Object> e : configArgs.entrySet()) {
            expandedConfig.put(e.getKey(), expandConfigVariable(cve, e.getValue(), keepSecrets));
        }
        return expandedConfig;
    }

    public static Map<String, Object> expandConfigVariables(ConfigVariableExpander cve, Map<String, Object> configArgs) {
        return expandConfigVariables(cve, configArgs, false);
    }

    @SuppressWarnings({"rawtypes", "unchecked"})
    public static Object expandConfigVariable(ConfigVariableExpander cve, Object valueToExpand, boolean keepSecrets) {
        if (valueToExpand instanceof List) {
            List list = (List) valueToExpand;
            List<Object> expandedObjects = new ArrayList<>();
            for (Object o : list) {
                expandedObjects.add(cve.expand(o, keepSecrets));
            }
            return expandedObjects;
        }
        if (valueToExpand instanceof Map) {
            // hidden recursion here expandConfigVariables -> expandConfigVariable
            return expandConfigVariables(cve, (Map<String, Object>) valueToExpand, keepSecrets);
        }
        if (valueToExpand instanceof String) {
            return cve.expand(valueToExpand, keepSecrets);
        }
        return valueToExpand;
    }

    public static Object expandConfigVariableKeepingSecrets(ConfigVariableExpander cve, Object valueToExpand) {
        return expandConfigVariable(cve, valueToExpand, true);
    }

    /**
     * Checks if a certain {@link Vertex} represents a {@link AbstractFilterDelegatorExt}.
     * @param vertex Vertex to check
     * @return True iff {@link Vertex} represents a {@link AbstractFilterDelegatorExt}
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

    public final class CompiledOrderedExecution extends CompiledExecution {

        @SuppressWarnings({"unchecked"})  private final RubyArray<RubyEvent> EMPTY_ARRAY = RubyUtil.RUBY.newEmptyArray();

        @Override
        public int compute(final QueueBatch batch, final boolean flush, final boolean shutdown) {
           return compute(batch.events(), flush, shutdown);
        }

        @Override
        public int compute(final Collection<RubyEvent> batch, final boolean flush, final boolean shutdown) {
            if (!batch.isEmpty()) {
                @SuppressWarnings({"unchecked"}) final RubyArray<RubyEvent> outputBatch = RubyUtil.RUBY.newArray();
                @SuppressWarnings({"unchecked"}) final RubyArray<RubyEvent> filterBatch = RubyUtil.RUBY.newArray(1);
                // send batch one-by-one as single-element batches down the filters
                for (final RubyEvent e : batch) {
                    filterBatch.set(0, e);
                    _compute(filterBatch, outputBatch, flush, shutdown);
                }
                compiledOutputs.compute(outputBatch, flush, shutdown);
                return outputBatch.size();
            } else if (flush || shutdown) {
                @SuppressWarnings({"unchecked"}) final RubyArray<RubyEvent> outputBatch = RubyUtil.RUBY.newArray();
                _compute(EMPTY_ARRAY, outputBatch, flush, shutdown);
                compiledOutputs.compute(outputBatch, flush, shutdown);
                return outputBatch.size();
            }
            return 0;
        }

        private void _compute(final RubyArray<RubyEvent> batch, final RubyArray<RubyEvent> outputBatch, final boolean flush, final boolean shutdown) {
            final Collection<RubyEvent> result = compiledFilters.compute(batch, flush, shutdown);
            copyNonCancelledEvents(result, outputBatch);
            compiledFilters.clear();
        }
    }

    public final class CompiledUnorderedExecution extends CompiledExecution {

        @Override
        public int compute(final QueueBatch batch, final boolean flush, final boolean shutdown) {
            return compute(batch.events(), flush, shutdown);
        }

        @Override
        public int compute(final Collection<RubyEvent> batch, final boolean flush, final boolean shutdown) {
            // we know for now this comes from batch.collection() which returns a LinkedHashSet
            final Collection<RubyEvent> result = compiledFilters.compute(RubyArray.newArray(RubyUtil.RUBY, batch), flush, shutdown);
            @SuppressWarnings({"unchecked"}) final RubyArray<RubyEvent> outputBatch = RubyUtil.RUBY.newArray(result.size());
            copyNonCancelledEvents(result, outputBatch);
            compiledFilters.clear();
            compiledOutputs.compute(outputBatch, flush, shutdown);
            return outputBatch.size();
        }
    }

    public interface Execution <QB extends QueueBatch> {
        /**
         * @return the number of events that was processed, could be less o greater than batch.size(), depending if
         *  the pipeline drops or clones events during the filter stage.
         * */
        int compute(final QB batch, final boolean flush, final boolean shutdown);
    }

    /**
     * Instances of this class represent a fully compiled pipeline execution. Note that this class
     * has a separate lifecycle from {@link CompiledPipeline} because it holds per (worker-thread)
     * state and thus needs to be instantiated once per thread.
     */
    public abstract class CompiledExecution implements Execution<QueueBatch> {

        /**
         * Compiled {@link IfVertex, indexed by their ID as returned by {@link Vertex#getId()}.
         */
        private final Map<String, SplitDataset> iffs = new HashMap<>(50);

        /**
         * Cached {@link Dataset} compiled from {@link PluginVertex} indexed by their ID as returned
         * by {@link Vertex#getId()} to avoid duplicate computations.
         */
        private final Map<String, Dataset> plugins = new HashMap<>(50);

        protected final Dataset compiledFilters;
        protected final Dataset compiledOutputs;

        CompiledExecution() {
            compiledFilters = compileFilters();
            compiledOutputs = compileOutputs();
        }

        public abstract int compute(final Collection<RubyEvent> batch, final boolean flush, final boolean shutdown);

        /**
         * Instantiates the graph of compiled filter section {@link Dataset}.
         * @return Compiled {@link Dataset} representing the filter section of the pipeline.
         */
        private Dataset compileFilters() {
            final Vertex separator = pipelineIR.getGraph()
                .vertices()
                .filter(v -> v instanceof SeparatorVertex)
                .findFirst()
                .orElseThrow(() -> new IllegalStateException("Missing Filter End Vertex"));
           return DatasetCompiler.terminalFilterDataset(flatten(Collections.emptyList(), separator));
        }

        /**
         * Instantiates the graph of compiled output section {@link Dataset}.
         * @return Compiled {@link Dataset} representing the output section of the pipeline.
         */
        private Dataset compileOutputs() {
            final Collection<Vertex> outputNodes = pipelineIR.getGraph()
                .allLeaves().filter(CompiledPipeline.this::isOutput)
                .collect(Collectors.toList());
            if (outputNodes.isEmpty()) {
                return Dataset.IDENTITY;
            } else {
                return DatasetCompiler.terminalOutputDataset(outputNodes.stream()
                    .map(leaf -> outputDataset(leaf, flatten(Collections.emptyList(), leaf)))
                    .collect(Collectors.toList()));
            }
        }

        /**
         * Build a {@link Dataset} representing the {@link RubyEvent}s after
         * the application of the given filter.
         * @param vertex Vertex of the filter to create this {@link Dataset} for
         * @param datasets All the datasets that have children passing into this filter
         * @return Filter {@link Dataset}
         */
        private Dataset filterDataset(final Vertex vertex, final Collection<Dataset> datasets) {
            final String vertexId = vertex.getId();

            if (!plugins.containsKey(vertexId)) {
                final ComputeStepSyntaxElement<Dataset> prepared =
                    DatasetCompiler.filterDataset(
                        flatten(datasets, vertex),
                        filters.get(vertexId)
                    );

                plugins.put(vertexId, prepared.instantiate());
            }

            return plugins.get(vertexId);
        }

        /**
         * Build a {@link Dataset} representing the {@link RubyEvent}s after
         * the application of the given output.
         * @param vertex Vertex of the output to create this {@link Dataset} for
         * @param datasets All the datasets that have children passing into this output
         * @return Output {@link Dataset}
         */
        private Dataset outputDataset(final Vertex vertex, final Collection<Dataset> datasets) {
            final String vertexId = vertex.getId();

            if (!plugins.containsKey(vertexId)) {
                final ComputeStepSyntaxElement<Dataset> prepared =
                    DatasetCompiler.outputDataset(
                        flatten(datasets, vertex),
                        outputs.get(vertexId),
                        outputs.size() == 1
                    );

                plugins.put(vertexId, prepared.instantiate());
            }

            return plugins.get(vertexId);
        }

        /**
         * Split the given {@link Dataset}s and return the dataset half of their elements that contains
         * the {@link RubyEvent} that fulfil the given {@link EventCondition}.
         * @param datasets Datasets that are the parents of the datasets to split
         * @param condition Condition that must be fulfilled
         * @param vertex Vertex id to cache the resulting {@link Dataset} under
         * @return The half of the datasets contents that fulfils the condition
         */
        private SplitDataset split(
            final Collection<Dataset> datasets,
            final EventCondition condition,
            final Vertex vertex)
        {
            final String vertexId = vertex.getId();
            SplitDataset conditional = iffs.get(vertexId);
            if (conditional == null) {
                final Collection<Dataset> dependencies = flatten(datasets, vertex);
                conditional = iffs.get(vertexId);
                // Check that compiling the dependencies did not already instantiate the conditional
                // by requiring its else branch.
                if (conditional == null) {
                    final ComputeStepSyntaxElement<SplitDataset> prepared =
                        DatasetCompiler.splitDataset(dependencies, condition);

                    conditional = prepared.instantiate();
                    iffs.put(vertexId, conditional);
                }

            }
            return conditional;
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
        private Collection<Dataset> flatten(
            final Collection<Dataset> datasets,
            final Vertex start)
        {
            final Collection<Dataset> result = compileDependencies(
                start,
                datasets,
                start.incomingVertices().filter(v -> isFilter(v) || isOutput(v) || v instanceof IfVertex)
            );
            return result.isEmpty() ? datasets : result;
        }

        /**
         * Compiles all child vertices for a given vertex.
         * @param datasets Datasets from previous stage
         * @param start Start Vertex that got expanded
         * @param dependencies Dependencies of {@code start}
         * @return Datasets compiled from vertex children
         */
        private Collection<Dataset> compileDependencies(
                final Vertex start,
                final Collection<Dataset> datasets,
                final Stream<Vertex> dependencies)
        {
            return dependencies.map(
                dependency -> {
                    if (isFilter(dependency)) {
                        return filterDataset(dependency, datasets);
                    } else if (isOutput(dependency)) {
                        return outputDataset(dependency, datasets);
                    } else {
                        // We know that it's an if vertex since the input children are either
                        // output, filter or if in type.
                        final IfVertex ifvert = (IfVertex) dependency;
                        final SplitDataset ifDataset = split(
                            datasets,
                            conditionalCompiler.buildCondition(ifvert.getBooleanExpression()),
                            dependency
                        );
                        // It is important that we double check that we are actually dealing with the
                        // positive/left branch of the if condition
                        if (ifvert.outgoingBooleanEdgesByType(true)
                            .anyMatch(edge -> Objects.equals(edge.getTo(), start)))
                        {
                            return ifDataset;
                        } else {
                            return ifDataset.right();
                        }
                    }
                }
            ).collect(Collectors.toList());
        }
    }
}
