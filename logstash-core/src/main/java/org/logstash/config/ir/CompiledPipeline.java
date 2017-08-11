package org.logstash.config.ir;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
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

    private CompiledPipeline.Dataset buildDataset() {
        CompiledPipeline.Dataset first = new RootDataset();
        final Map<String, CompiledPipeline.Dataset> filterplugins = new HashMap<>();
        final Collection<CompiledPipeline.Dataset> datasets =
            flatten(Collections.singleton(first), graph.getOutputPluginVertices().get(0),
                filterplugins
            );
        return new CompiledPipeline.Dataset() {
            @Override
            public RubyArray compute(final RubyArray originals) {
                final RubyArray res = RubyUtil.RUBY.newArray();
                datasets.forEach(dataset -> res.addAll(dataset.compute(originals)));
                return res;
            }
        };
    }

    private Collection<CompiledPipeline.Dataset> flatten(
        final Collection<CompiledPipeline.Dataset> parents, final Vertex start,
        final Map<String, CompiledPipeline.Dataset> filterMap) {
        final Collection<Vertex> endings = start.getIncomingVertices();
        if (endings.isEmpty()) {
            return parents;
        }
        final Collection<CompiledPipeline.Dataset> res = new ArrayList<>();
        for (final Vertex end : endings) {
            CompiledPipeline.Dataset newNode = null;
            Collection<CompiledPipeline.Dataset> newparents = flatten(parents, end, filterMap);
            if (newparents.isEmpty()) {
                newparents = new ArrayList<>(parents);
            }
            if (end instanceof PluginVertex) {
                if (!filterMap.containsKey(end.getId())) {
                    newNode = filterDataset(newparents, filters.get(end.getId()));
                    filterMap.put(end.getId(), newNode);
                } else {
                    newNode = filterMap.get(end.getId());
                }
            } else if (end instanceof IfVertex) {
                final EventCondition iff = buildCondition((IfVertex) end);
                if (((IfVertex) end).getOutgoingBooleanEdgesByType(true).stream()
                    .anyMatch(edge -> Objects.equals(edge.getTo(), start))) {
                    newNode = splitRight(newparents, iff);
                } else {
                    newNode = splitLeft(newparents, iff);
                }
            }
            if (newNode != null) {
                res.add(newNode);
            }
        }
        return res;
    }

    private static CompiledPipeline.Dataset splitLeft(
        final Collection<CompiledPipeline.Dataset> dataset,
        final EventCondition condition) {
        return new CompiledPipeline.SplitDataset(
            dataset, EventCondition.Factory.not(condition)
        );
    }

    private static CompiledPipeline.Dataset splitRight(
        final Collection<CompiledPipeline.Dataset> dataset,
        final EventCondition condition) {
        return new CompiledPipeline.SplitDataset(dataset, condition);
    }

    private static CompiledPipeline.Dataset filterDataset(
        final Collection<CompiledPipeline.Dataset> parents,
        final RubyIntegration.Filter filter) {
        return new CompiledPipeline.FilteredDataset(parents, filter);
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

    private interface Dataset {

        RubyArray compute(RubyArray originals);
    }

    private final class RootDataset implements CompiledPipeline.Dataset {

        @Override
        public RubyArray compute(final RubyArray originals) {
            return originals;
        }
    }

    private static final class FilteredDataset implements CompiledPipeline.Dataset {

        private final Collection<CompiledPipeline.Dataset> parents;

        private final RubyIntegration.Filter func;

        private final RubyArray data;

        private boolean done;

        FilteredDataset(Collection<CompiledPipeline.Dataset> parents,
            final RubyIntegration.Filter func) {
            this.parents = parents;
            this.func = func;
            data = RubyUtil.RUBY.newArray();
        }

        @Override
        public RubyArray compute(final RubyArray originals) {
            if (done) {
                return data;
            }
            final RubyArray buffer = RubyUtil.RUBY.newArray();
            for (final CompiledPipeline.Dataset set : parents) {
                buffer.addAll(set.compute(originals));
            }
            done = true;
            data.addAll(func.multiFilter(buffer));
            return data;
        }
    }

    private static final class SplitDataset implements CompiledPipeline.Dataset {

        private final Collection<CompiledPipeline.Dataset> parents;

        private final EventCondition func;

        private boolean done;

        private final RubyArray data;

        SplitDataset(Collection<CompiledPipeline.Dataset> parents, final EventCondition func) {
            this.parents = parents;
            this.func = func;
            done = false;
            data = RubyUtil.RUBY.newArray();
        }

        @Override
        public RubyArray compute(final RubyArray originals) {
            if (done) {
                return data;
            }
            for (final CompiledPipeline.Dataset set : parents) {
                for (final Object event : set.compute(originals)) {
                    if (func.fulfilled((JrubyEventExtLibrary.RubyEvent) event)) {
                        data.add(event);
                    }
                }
            }
            done = true;
            return data;
        }
    }
}
