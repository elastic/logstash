package org.logstash.config.ir;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;
import org.jruby.RubyArray;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.Rubyfier;
import org.logstash.config.ir.compiler.EventCondition;
import org.logstash.config.ir.compiler.RubyIntegration;
import org.logstash.config.ir.graph.IfVertex;
import org.logstash.config.ir.graph.PluginVertex;
import org.logstash.config.ir.graph.Vertex;
import org.logstash.ext.JrubyEventExtLibrary;

public final class CompiledPipeline {

    private static final EventCondition[] NO_CONDITIONS =
        new EventCondition[0];
    public static final CompiledPipeline.ConditionalFilter[] EMPTY_CHILDREN =
        new CompiledPipeline.ConditionalFilter[0];

    private final Collection<IRubyObject> inputs = new ArrayList<>();

    private final HashMap<String, ConditionalFilter> filters = new HashMap<>();

    private final Collection<CompiledPipeline.ConditionalFilter> rootFilters = new ArrayList<>();

    private final Collection<RubyIntegration.Output> outputs = new ArrayList<>();

    private final PipelineIR graph;

    public CompiledPipeline(final PipelineIR graph) {
        this.graph = graph;
    }

    public RubyIntegration.Plugin registerPlugin(final RubyIntegration.Plugin plugin) {
        plugin.register();
        return plugin;
    }

    public Collection<RubyIntegration.Output> outputs(final RubyIntegration.Pipeline pipeline) {
        if (outputs.isEmpty()) {
            graph.getOutputPluginVertices().forEach(v -> {
                final PluginDefinition def = v.getPluginDefinition();
                outputs.add(pipeline.buildOutput(
                    RubyUtil.RUBY.newString(def.getName()),
                    Rubyfier.deep(RubyUtil.RUBY, def.getArguments())
                ));
            });
        }
        return outputs;
    }

    public Collection<RubyIntegration.Filter> filters(final RubyIntegration.Pipeline pipeline) {
        if (filters.isEmpty()) {
            final List<PluginVertex> plugins = new ArrayList<>(graph.getFilterPluginVertices());
            plugins.sort(Comparator.comparingInt(Vertex::rank));
            int rank = Integer.MAX_VALUE;
            while (!plugins.isEmpty()) {
                final PluginVertex next = plugins.remove(0);
                if (next.rank() > rank) {
                    continue;
                }
                rank = next.rank();
                rootFilters.add(
                    buildConditionalFilter(pipeline, next)
                );
            }
        }
        return filters.values().stream().map(fil -> fil.filter).collect(Collectors.toList());
    }

    private CompiledPipeline.ConditionalFilter buildConditionalFilter(
        final RubyIntegration.Pipeline pipeline,
        final PluginVertex filterPlugin) {
        final CompiledPipeline.ConditionalFilter filter;
        if (!this.filters.containsKey(filterPlugin.getId())) {
            filter = new CompiledPipeline.ConditionalFilter(
                buildFilter(pipeline, filterPlugin.getPluginDefinition()),
                wrapCondition(filterPlugin).toArray(NO_CONDITIONS),
                filterPlugin.descendants()
                    .filter(vert -> this.graph.getFilterPluginVertices().contains(vert))
                    .map(vertex -> buildConditionalFilter(pipeline, (PluginVertex) vertex))
                    .collect(Collectors.toList())
                    .toArray(EMPTY_CHILDREN)
            );
            filters.put(filterPlugin.getId(), filter);
        } else {
            filter = filters.get(filterPlugin.getId());
        }
        return filter;
    }

    private static RubyIntegration.Filter buildFilter(final RubyIntegration.Pipeline pipeline,
        final PluginDefinition def) {
        return pipeline.buildFilter(
            RubyUtil.RUBY.newString(def.getName()),
            Rubyfier.deep(RubyUtil.RUBY, def.getArguments())
        );
    }

    public Collection<IRubyObject> inputs(final RubyIntegration.Pipeline pipeline) {
        if (inputs.isEmpty()) {
            graph.getInputPluginVertices().forEach(v -> {
                final PluginDefinition def = v.getPluginDefinition();
                inputs.add(pipeline.buildInput(
                    RubyUtil.RUBY.newString(def.getName()),
                    Rubyfier.deep(RubyUtil.RUBY, def.getArguments())
                ));
            });
        }
        return inputs;
    }

    public void filter(final JrubyEventExtLibrary.RubyEvent event, final RubyArray generated) {
        RubyArray events = RubyUtil.RUBY.newArray();
        events.add(event);
        final RubyArray excluded = RubyUtil.RUBY.newArray();
        for (final CompiledPipeline.ConditionalFilter filter : rootFilters) {
            events = filter.execute(events, excluded);
            events.addAll(excluded);
            excluded.clear();
        }
        generated.addAll(events);
        generated.addAll(excluded);
    }

    public void output(final RubyArray events) {
        outputs.forEach(output -> output.multiReceive(events));
    }

    public Collection<RubyIntegration.Filter> shutdownFlushers() {
        return filters.values().stream().filter(f -> f.flushes()).map(f -> f.filter).collect(
            Collectors.toList());
    }

    public Collection<RubyIntegration.Filter> periodicFlushers() {
        return shutdownFlushers().stream().filter(
            filter -> filter.periodicFlush()).collect(Collectors.toList());
    }

    private static boolean ifPointsAt(final PluginVertex positive, final IfVertex iff) {
        return iff.getOutgoingBooleanEdgesByType(true).stream()
            .filter(e -> e.getTo().equals(positive)).count() > 0L;
    }

    private static boolean notPointsAt(final Vertex negative, final IfVertex iff) {
        return iff.getOutgoingBooleanEdgesByType(false).stream()
            .filter(e -> e.getTo().equals(negative)).count() > 0L;
    }

    private static Collection<EventCondition> wrapCondition(
        final PluginVertex filterPlugin) {
        final Collection<EventCondition> conditions = new ArrayList<>(5);
        filterPlugin.getIncomingVertices().stream()
            .filter(vertex -> vertex instanceof IfVertex)
            .forEach(vertex -> {
                    final IfVertex iff = (IfVertex) vertex;
                    if (ifPointsAt(filterPlugin, iff)) {
                        final EventCondition condition = buildCondition(iff);
                        if (condition != null) {
                            conditions.add(condition);
                        }
                    } else if (notPointsAt(filterPlugin, iff)) {
                        final EventCondition condition = buildCondition(iff);
                        if (condition != null) {
                            conditions.add(EventCondition.Factory.not(condition));
                        }
                        Optional<Vertex> next = iff.getIncomingVertices().stream().findFirst();
                        while (next.isPresent() && next.get() instanceof IfVertex) {
                            final IfVertex nextif = (IfVertex) next.get();
                            final EventCondition nextc = buildCondition(nextif);
                            if (nextc != null) {
                                conditions.add(EventCondition.Factory.not(nextc));
                            }
                            next = nextif.getIncomingVertices().stream().findFirst();
                        }
                    }
                }
            );
        return conditions;
    }

    private static EventCondition buildCondition(final IfVertex iff) {
        try {
            return EventCondition.Factory.buildCondition(iff.getBooleanExpression());
        } catch (final Exception ex) {
            ex.printStackTrace();
            throw ex;
        }
    }

    private static final class ConditionalFilter {

        private final RubyIntegration.Filter filter;

        private final CompiledPipeline.ConditionalFilter[] children;

        private final EventCondition[] conditions;

        ConditionalFilter(final RubyIntegration.Filter filter,
            final EventCondition[] conditions,
            final CompiledPipeline.ConditionalFilter children[]) {
            this.filter = filter;
            this.conditions = conditions;
            this.children = children;
        }

        public RubyArray execute(final RubyArray events, final RubyArray excluded) {
            final RubyArray valid = RubyUtil.RUBY.newArray();
            for (final Object obj : events) {
                if (fulfilled((JrubyEventExtLibrary.RubyEvent) obj)) {
                    valid.add(obj);
                } else {
                    excluded.add(obj);
                }
            }
            RubyArray temp = filter.multiFilter(valid);
            final RubyArray result = RubyUtil.RUBY.newArray();
            for (final CompiledPipeline.ConditionalFilter filter : children) {
                final RubyArray childExcluded = RubyUtil.RUBY.newArray();
                result.addAll(filter.execute(temp, childExcluded));
                temp = childExcluded;
            }
            result.addAll(temp);
            return result;
        }

        public boolean flushes() {
            return filter.hasFlush();
        }

        private boolean fulfilled(final JrubyEventExtLibrary.RubyEvent event) {
            for (final EventCondition cond : conditions) {
                if (!cond.fulfilled(event)) {
                    return false;
                }
            }
            return true;
        }
    }

}
