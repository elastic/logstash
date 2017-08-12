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
import org.jruby.RubyArray;
import org.jruby.RubyHash;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.Rubyfier;
import org.logstash.config.ir.compiler.Dataset;
import org.logstash.config.ir.compiler.EventCondition;
import org.logstash.config.ir.compiler.RubyIntegration;
import org.logstash.config.ir.graph.IfVertex;
import org.logstash.config.ir.graph.PluginVertex;
import org.logstash.config.ir.graph.Vertex;
import org.logstash.config.ir.imperative.PluginStatement;
import org.logstash.ext.JrubyEventExtLibrary;

public final class CompiledPipeline {

    private final Collection<IRubyObject> inputs = new HashSet<>();

    private final HashMap<String, RubyIntegration.Filter> filters = new HashMap<>();

    private final Collection<RubyIntegration.Output> outputs = new HashSet<>();

    private final PipelineIR graph;

    private final RubyIntegration.Pipeline pipeline;

    public CompiledPipeline(final PipelineIR graph, final RubyIntegration.Pipeline pipeline) {
        this.graph = graph;
        this.pipeline = pipeline;
        setupInputs();
        setupFilters();
        setupOutputs();
    }

    public RubyIntegration.Plugin registerPlugin(final RubyIntegration.Plugin plugin) {
        plugin.register();
        return plugin;
    }

    public void filter(final JrubyEventExtLibrary.RubyEvent event, final RubyArray generated) {
        final RubyArray incoming = RubyUtil.RUBY.newArray();
        incoming.add(event);
        generated.addAll(buildDataset().compute(incoming));
    }

    public void output(final RubyArray events) {
        outputs.forEach(output -> output.multiReceive(events));
    }

    public Collection<RubyIntegration.Filter> shutdownFlushers() {
        return filters.values().stream().filter(RubyIntegration.Filter::hasFlush).collect(
            Collectors.toList());
    }

    public Collection<RubyIntegration.Filter> periodicFlushers() {
        return shutdownFlushers().stream().filter(
            filter -> filter.periodicFlush()).collect(Collectors.toList());
    }

    public Collection<RubyIntegration.Output> outputs() {
        return outputs;
    }

    public Collection<RubyIntegration.Filter> filters() {
        return new ArrayList<>(filters.values());
    }

    public Collection<IRubyObject> inputs() {
        return inputs;
    }

    private void setupOutputs() {
        graph.getOutputPluginVertices().forEach(v -> {
            final PluginDefinition def = v.getPluginDefinition();
            outputs.add(pipeline.buildOutput(
                RubyUtil.RUBY.newString(def.getName()),
                RubyUtil.RUBY.newFixnum(v.getSourceWithMetadata().getLine()),
                RubyUtil.RUBY.newFixnum(v.getSourceWithMetadata().getColumn()),
                Rubyfier.deep(RubyUtil.RUBY, def.getArguments())
            ));
        });
    }

    private void setupFilters() {
        for (final PluginVertex plugin : graph.getFilterPluginVertices()) {
            if (!filters.containsKey(plugin.getId())) {
                filters.put(plugin.getId(), buildFilter(plugin));
            }
        }
    }

    private void setupInputs() {
        graph.getInputPluginVertices().forEach(v -> {
            final PluginDefinition def = v.getPluginDefinition();
            final RubyHash converted = RubyHash.newHash(RubyUtil.RUBY);
            for (final Map.Entry<String, Object> entry : def.getArguments().entrySet()) {
                final Object value = entry.getValue();
                if (value instanceof PluginStatement) {
                    final PluginDefinition codec =
                        ((PluginStatement) value).getPluginDefinition();
                    converted.put(entry.getKey(), pipeline.buildCodec(
                        RubyUtil.RUBY.newString(codec.getName()),
                        Rubyfier.deep(RubyUtil.RUBY, codec.getArguments())
                    ));
                } else {
                    converted.put(entry.getKey(), entry.getValue());
                }
            }
            inputs.add(pipeline.buildInput(
                RubyUtil.RUBY.newString(def.getName()),
                RubyUtil.RUBY.newFixnum(v.getSourceWithMetadata().getLine()),
                RubyUtil.RUBY.newFixnum(v.getSourceWithMetadata().getColumn()),
                converted
            ));
        });
    }

    private RubyIntegration.Filter buildFilter(final PluginVertex vertex) {
        final PluginDefinition def = vertex.getPluginDefinition();
        return pipeline.buildFilter(
            RubyUtil.RUBY.newString(def.getName()),
            RubyUtil.RUBY.newFixnum(vertex.getSourceWithMetadata().getLine()),
            RubyUtil.RUBY.newFixnum(vertex.getSourceWithMetadata().getColumn()),
            Rubyfier.deep(RubyUtil.RUBY, def.getArguments())
        );
    }

    private Dataset buildDataset() {
        final Dataset first = new Dataset.RootDataset();
        final Map<String, Dataset> filterplugins = new HashMap<>();
        final Collection<Dataset> datasets = new ArrayList<>();
        graph.getGraph().getAllLeaves().stream().sorted(Comparator.comparing(Vertex::hashPrefix))
            .forEachOrdered(
                leaf -> {
                    final Collection<Dataset> parents =
                        flatten(Collections.singleton(first), leaf, filterplugins);
                    if (graph.getFilterPluginVertices().contains(leaf)) {
                        datasets.add(filterDataset(leaf.getId(), filterplugins, parents));
                    } else if (leaf instanceof IfVertex) {
                        datasets.add(splitRight(parents, buildCondition((IfVertex) leaf)));
                     } else {
                        datasets.addAll(parents);
                    }
                }
            );
        return new Dataset.SumDataset(datasets);
    }

    private Collection<Dataset> flatten(
        final Collection<Dataset> parents, final Vertex start,
        final Map<String, Dataset> filterMap) {
        final Collection<Vertex> endings = start.getIncomingVertices();
        if (endings.isEmpty()) {
            return parents;
        }
        final Collection<Dataset> res = new ArrayList<>();
        for (final Vertex end : endings) {
            Collection<Dataset> newparents = flatten(parents, end, filterMap);
            if (newparents.isEmpty()) {
                newparents = new ArrayList<>(parents);
            }
            if (graph.getFilterPluginVertices().contains(end)) {
                res.add(filterDataset(end.getId(), filterMap, newparents));
            } else if (end instanceof IfVertex) {
                final IfVertex ifvert = (IfVertex) end;
                final EventCondition iff = buildCondition(ifvert);
                if (ifvert.getOutgoingBooleanEdgesByType(true).stream()
                    .anyMatch(edge -> Objects.equals(edge.getTo(), start))) {
                    res.add(splitLeft(newparents, iff));
                } else {
                    res.add(splitRight(newparents, iff));
                }
            }
        }
        return res;
    }

    private static Dataset splitRight(final Collection<Dataset> dataset,
        final EventCondition condition) {
        return new Dataset.SplitDataset(
            dataset, EventCondition.Factory.not(condition)
        );
    }

    private static Dataset splitLeft(final Collection<Dataset> dataset,
        final EventCondition condition) {
        return new Dataset.SplitDataset(dataset, condition);
    }

    private Dataset filterDataset(final String vertex, final Map<String, Dataset> cache,
        final Collection<Dataset> parents) {
        final Dataset dataset;
        if (cache.containsKey(vertex)) {
            dataset = cache.get(vertex);
        } else {
            dataset = new Dataset.FilteredDataset(parents, filters.get(vertex));
            cache.put(vertex, dataset);
        }
        return dataset;
    }

    /**
     * @todo Remove weird print
     */
    private static EventCondition buildCondition(final IfVertex iff) {
        try {
            return EventCondition.Factory.buildCondition(iff.getBooleanExpression());
        } catch (final Exception ex) {
            ex.printStackTrace();
            throw ex;
        }
    }

}
