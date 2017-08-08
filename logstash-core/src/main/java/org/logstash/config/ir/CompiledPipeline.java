package org.logstash.config.ir;

import java.util.ArrayList;
import java.util.Collection;
import java.util.HashSet;
import java.util.stream.Collectors;
import org.jruby.RubyArray;
import org.jruby.RubyString;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.FieldReference;
import org.logstash.PathCache;
import org.logstash.Rubyfier;
import org.logstash.bivalues.BiValues;
import org.logstash.config.ir.expression.EventValueExpression;
import org.logstash.config.ir.expression.ValueExpression;
import org.logstash.config.ir.expression.binary.Eq;
import org.logstash.config.ir.graph.IfVertex;
import org.logstash.ext.JrubyEventExtLibrary;

public final class CompiledPipeline {

    private static final CompiledPipeline.Condition[] NO_CONDITIONS =
        new CompiledPipeline.Condition[0];

    private final Collection<IRubyObject> inputs = new HashSet<>();
    private final Collection<CompiledPipeline.ConditionalFilter> filters = new HashSet<>();
    private final Collection<CompiledPipeline.Output> outputs = new HashSet<>();

    private final PipelineIR graph;

    public CompiledPipeline(final PipelineIR graph) {
        this.graph = graph;
    }

    public Plugin registerPlugin(final Plugin plugin) {
        plugin.register();
        return plugin;
    }

    public Collection<CompiledPipeline.Output> outputs(final Pipeline pipeline) {
        if (outputs.isEmpty()) {
            graph.getOutputPluginVertices().forEach(v -> {
                final PluginDefinition def = v.getPluginDefinition();
                outputs.add((CompiledPipeline.Output) pipeline.buildOutput(
                    BiValues.RUBY.newString(def.getName()),
                    Rubyfier.deep(BiValues.RUBY, def.getArguments())
                ));
            });
        }
        return outputs;
    }

    public Collection<CompiledPipeline.Filter> filters(final Pipeline pipeline) {
        if (filters.isEmpty()) {
            graph.getFilterPluginVertices().forEach(filterPlugin -> {
                final Collection<CompiledPipeline.Condition> conditions = new ArrayList<>(5);
                filterPlugin.getIncomingVertices().stream()
                    .filter(vertex -> vertex instanceof IfVertex)
                    .forEach(vertex -> {
                            final IfVertex iff = (IfVertex) vertex;
                            if (iff.getBooleanExpression() instanceof Eq) {
                                final Eq equals = (Eq) iff.getBooleanExpression();
                                if (equals.getLeft() instanceof EventValueExpression &&
                                    equals.getRight() instanceof ValueExpression) {
                                    conditions.add(new FieldEquals(
                                        ((EventValueExpression) equals.getLeft()).getFieldName(),
                                        ((ValueExpression) equals.getRight()).get().toString()
                                    ));
                                }
                            }
                        }
                    );
                final PluginDefinition def = filterPlugin.getPluginDefinition();
                filters.add(
                    new CompiledPipeline.ConditionalFilter(
                        pipeline.buildFilter(
                            BiValues.RUBY.newString(def.getName()),
                            Rubyfier.deep(BiValues.RUBY, def.getArguments())
                        ), conditions.toArray(NO_CONDITIONS)));
            });
        }
        return filters.stream().map(f -> f.filter).collect(Collectors.toList());
    }

    public Collection<IRubyObject> inputs(final Pipeline pipeline) {
        if (inputs.isEmpty()) {
            graph.getInputPluginVertices().forEach(v -> {
                final PluginDefinition def = v.getPluginDefinition();
                inputs.add(pipeline.buildInput(
                    BiValues.RUBY.newString(def.getName()),
                    Rubyfier.deep(BiValues.RUBY, def.getArguments())
                ));
            });
        }
        return inputs;
    }

    public void filter(final JrubyEventExtLibrary.RubyEvent event, final RubyArray generated) {
        RubyArray events = BiValues.RUBY.newArray();
        events.add(event);
        for (final CompiledPipeline.ConditionalFilter filter : filters) {
            events = filter.execute(events);
        }
        generated.addAll(events);
    }

    public void output(final RubyArray events) {
        outputs.forEach(output -> output.multiReceive(events));
    }

    public Collection<CompiledPipeline.Filter> shutdownFlushers() {
        return filters.stream().filter(f -> f.flushes()).map(f -> f.filter).collect(
            Collectors.toList());
    }

    public Collection<CompiledPipeline.Filter> periodicFlushers() {
        return shutdownFlushers().stream().filter(
            filter -> filter.periodicFlush()).collect(Collectors.toList());
    }

    private static IRubyObject callRuby(final IRubyObject object, final String method) {
        return object.callMethod(BiValues.RUBY.getCurrentContext(), method);
    }

    private static IRubyObject callRuby(final IRubyObject object, final String method,
        final IRubyObject[] args) {
        return object.callMethod(BiValues.RUBY.getCurrentContext(), method, args);
    }

    private static final class ConditionalFilter {

        private final CompiledPipeline.Filter filter;

        private final CompiledPipeline.Condition[] conditions;

        ConditionalFilter(final CompiledPipeline.Filter filter,
            final CompiledPipeline.Condition[] conditions) {
            this.filter = filter;
            this.conditions = conditions;
        }

        public RubyArray execute(final RubyArray events) {
            final RubyArray valid = BiValues.RUBY.newArray();
            final RubyArray output = BiValues.RUBY.newArray();
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
            for (final CompiledPipeline.Condition cond : conditions) {
                if (!cond.fulfilled(event)) {
                    return false;
                }
            }
            return true;
        }
    }

    private interface Condition {

        boolean fulfilled(JrubyEventExtLibrary.RubyEvent event);
    }

    public interface Plugin {
        void register();
    }

    public interface Filter extends Plugin {

        RubyArray multiFilter(RubyArray events);

        boolean hasFlush();

        boolean periodicFlush();
    }

    public interface Output extends Plugin {
        void multiReceive(RubyArray events);
    }

    public interface Pipeline {

        IRubyObject buildInput(RubyString name, IRubyObject args);

        CompiledPipeline.Output buildOutput(RubyString name, IRubyObject args);

        CompiledPipeline.Filter buildFilter(RubyString name, IRubyObject args);
    }

    private final class FieldEquals implements CompiledPipeline.Condition {

        private final FieldReference field;

        private final RubyString value;

        FieldEquals(final String field, final String value) {
            this.field = PathCache.cache(field);
            this.value = BiValues.RUBY.newString(value);
        }

        @Override
        public boolean fulfilled(final JrubyEventExtLibrary.RubyEvent event) {
            return value.equals(event.getEvent().getUnconvertedField(field));
        }
    }
}
