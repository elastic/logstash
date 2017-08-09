package org.logstash.config.ir;

import java.util.ArrayList;
import java.util.Collection;
import java.util.HashSet;
import java.util.Optional;
import java.util.stream.Collectors;
import org.jruby.RubyArray;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.Rubyfier;
import org.logstash.config.ir.compiler.EventCondition;
import org.logstash.config.ir.compiler.RubyIntegration;
import org.logstash.config.ir.expression.BooleanExpression;
import org.logstash.config.ir.expression.unary.Not;
import org.logstash.config.ir.graph.IfVertex;
import org.logstash.config.ir.graph.PluginVertex;
import org.logstash.config.ir.graph.Vertex;
import org.logstash.ext.JrubyEventExtLibrary;

public final class CompiledPipeline {

    private static final EventCondition[] NO_CONDITIONS =
        new EventCondition[0];

    private final Collection<IRubyObject> inputs = new HashSet<>();
    private final Collection<CompiledPipeline.ConditionalFilter> filters = new HashSet<>();
    private final Collection<RubyIntegration.Output> outputs = new HashSet<>();

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
            graph.getFilterPluginVertices().forEach(filterPlugin -> {
                final PluginDefinition def = filterPlugin.getPluginDefinition();
                filters.add(
                    new CompiledPipeline.ConditionalFilter(
                        pipeline.buildFilter(
                            RubyUtil.RUBY.newString(def.getName()),
                            Rubyfier.deep(RubyUtil.RUBY, def.getArguments())
                        ), wrapCondition(filterPlugin).toArray(NO_CONDITIONS)));
            });
        }
        return filters.stream().map(fil -> fil.filter).collect(Collectors.toList());
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
        for (final CompiledPipeline.ConditionalFilter filter : filters) {
            events = filter.execute(events);
        }
        generated.addAll(events);
    }

    public void output(final RubyArray events) {
        outputs.forEach(output -> output.multiReceive(events));
    }

    public Collection<RubyIntegration.Filter> shutdownFlushers() {
        return filters.stream().filter(f -> f.flushes()).map(f -> f.filter).collect(
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
        final EventCondition condition;
        if (iff.getBooleanExpression() instanceof Not) {
            condition = EventCondition.Factory.not(EventCondition.Factory.buildCondition(
                (BooleanExpression) ((Not) iff.getBooleanExpression()).getExpression())
            );
        } else {
            condition = EventCondition.Factory.buildCondition(iff.getBooleanExpression());
        }
        return condition;
    }

    private static final class ConditionalFilter {

        private final RubyIntegration.Filter filter;

        private final EventCondition[] conditions;

        ConditionalFilter(final RubyIntegration.Filter filter,
            final EventCondition[] conditions) {
            this.filter = filter;
            this.conditions = conditions;
        }

        public RubyArray execute(final RubyArray events) {
            final RubyArray valid = RubyUtil.RUBY.newArray();
            final RubyArray output = RubyUtil.RUBY.newArray();
            for (final Object obj : events) {
                if (fulfilled((JrubyEventExtLibrary.RubyEvent) obj)) {
                    valid.add(obj);
                } else {
                    output.add(obj);
                }
            }
            output.addAll(filter.multiFilter(valid));
            return output;
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
