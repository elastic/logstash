package org.logstash.config.ir;

import java.util.ArrayList;
import java.util.Collection;
import java.util.HashSet;
import java.util.List;
import java.util.regex.Pattern;
import java.util.stream.Collectors;
import org.jruby.RubyArray;
import org.jruby.RubyString;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.ConvertedList;
import org.logstash.FieldReference;
import org.logstash.PathCache;
import org.logstash.Rubyfier;
import org.logstash.bivalues.BiValues;
import org.logstash.config.ir.expression.EventValueExpression;
import org.logstash.config.ir.expression.ValueExpression;
import org.logstash.config.ir.expression.binary.Eq;
import org.logstash.config.ir.expression.binary.In;
import org.logstash.config.ir.expression.binary.RegexEq;
import org.logstash.config.ir.graph.IfVertex;
import org.logstash.config.ir.graph.PluginVertex;
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

    public CompiledPipeline.Plugin registerPlugin(final CompiledPipeline.Plugin plugin) {
        plugin.register();
        return plugin;
    }

    public Collection<CompiledPipeline.Output> outputs(final CompiledPipeline.Pipeline pipeline) {
        if (outputs.isEmpty()) {
            graph.getOutputPluginVertices().forEach(v -> {
                final PluginDefinition def = v.getPluginDefinition();
                outputs.add(pipeline.buildOutput(
                    BiValues.RUBY.newString(def.getName()),
                    Rubyfier.deep(BiValues.RUBY, def.getArguments())
                ));
            });
        }
        return outputs;
    }

    public Collection<CompiledPipeline.Filter> filters(final CompiledPipeline.Pipeline pipeline) {
        if (filters.isEmpty()) {
            graph.getFilterPluginVertices().forEach(filterPlugin -> {
                final Collection<CompiledPipeline.Condition> conditions = new ArrayList<>(5);
                wrapCondition(filterPlugin, conditions);
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

    public Collection<IRubyObject> inputs(final CompiledPipeline.Pipeline pipeline) {
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

    private static boolean ifPointsAt(final PluginVertex positive, final IfVertex iff) {
        return iff.getOutgoingBooleanEdgesByType(true).stream()
            .filter(e -> e.getTo().equals(positive)).count() > 0L;
    }

    private static boolean notPointsAt(final PluginVertex negative, final IfVertex iff) {
        return iff.getOutgoingBooleanEdgesByType(false).stream()
            .filter(e -> e.getTo().equals(negative)).count() > 0L;
    }

    private static void wrapCondition(final PluginVertex filterPlugin,
        final Collection<CompiledPipeline.Condition> conditions) {
        filterPlugin.getIncomingVertices().stream()
            .filter(vertex -> vertex instanceof IfVertex)
            .forEach(vertex -> {
                    final IfVertex iff = (IfVertex) vertex;
                    if (ifPointsAt(filterPlugin, iff)) {
                        final CompiledPipeline.Condition condition = buildCondition(iff);
                        if (condition != null) {
                            conditions.add(condition);
                        }
                    } else if (notPointsAt(filterPlugin, iff)) {
                        final CompiledPipeline.Condition condition = buildCondition(iff);
                        if (condition != null) {
                            conditions.add(new Negated(condition));
                        }
                    }
                }
            );
    }

    private static CompiledPipeline.Condition buildCondition(final IfVertex iff) {
        CompiledPipeline.Condition condition = null;
        if (iff.getBooleanExpression() instanceof Eq) {
            final Eq equals = (Eq) iff.getBooleanExpression();
            if (equals.getLeft() instanceof EventValueExpression &&
                equals.getRight() instanceof ValueExpression) {
                condition = new CompiledPipeline.FieldEquals(
                    ((EventValueExpression) equals.getLeft())
                        .getFieldName(),
                    ((ValueExpression) equals.getRight()).get().toString()
                );
            }
        } else if (iff.getBooleanExpression() instanceof RegexEq) {
            final RegexEq regex = (RegexEq) iff.getBooleanExpression();
            if (regex.getLeft() instanceof EventValueExpression &&
                regex.getRight() instanceof ValueExpression) {
                condition = new CompiledPipeline.FieldMatches(
                    ((EventValueExpression) regex.getLeft()).getFieldName(),
                    ((ValueExpression) regex.getRight()).get().toString()
                );
            }
        } else if (iff.getBooleanExpression() instanceof In) {
            final In in = (In) iff.getBooleanExpression();
            if (in.getLeft() instanceof EventValueExpression &&
                in.getRight() instanceof ValueExpression
                &&
                (((ValueExpression) in.getRight()).get() instanceof String
                    || ((ValueExpression) in.getRight())
                    .get() instanceof Number)) {
                condition = new CompiledPipeline.FieldArrayContainsValue(
                    PathCache.cache(((EventValueExpression) in.getLeft())
                        .getFieldName()),
                    ((ValueExpression) in.getRight()).get().toString()
                );
            } else if (in.getRight() instanceof EventValueExpression &&
                in.getLeft() instanceof ValueExpression
                &&
                (((ValueExpression) in.getLeft()).get() instanceof String
                    || ((ValueExpression) in.getLeft())
                    .get() instanceof Number)) {
                condition = new CompiledPipeline.FieldArrayContainsValue(
                    PathCache.cache(((EventValueExpression) in.getRight())
                        .getFieldName()),
                    ((ValueExpression) in.getLeft()).get().toString()
                );
            } else if (in.getLeft() instanceof EventValueExpression &&
                in.getRight() instanceof ValueExpression
                &&
                ((ValueExpression) in.getRight()).get() instanceof List) {
                condition = new CompiledPipeline.FieldContainsListedValue(
                    PathCache.cache(((EventValueExpression) in.getLeft())
                        .getFieldName()),
                    (List) ((ValueExpression) in.getRight()).get()
                );
            } else if (in.getRight() instanceof EventValueExpression &&
                in.getLeft() instanceof ValueExpression
                &&
                ((ValueExpression) in.getLeft()).get() instanceof List) {
                condition = new CompiledPipeline.FieldContainsListedValue(
                    PathCache.cache(((EventValueExpression) in.getRight())
                        .getFieldName()),
                    (List) ((ValueExpression) in.getLeft()).get()
                );
            } else if (in.getRight() instanceof EventValueExpression &&
                in.getLeft() instanceof EventValueExpression) {
                condition =
                    new CompiledPipeline.FieldArrayContainsFieldValue(
                        PathCache
                            .cache(((EventValueExpression) in.getRight())
                                .getFieldName()),
                        PathCache
                            .cache(((EventValueExpression) in.getLeft())
                                .getFieldName())
                    );
            }
        }
        return condition;
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

    public interface Filter extends CompiledPipeline.Plugin {

        RubyArray multiFilter(RubyArray events);

        boolean hasFlush();

        boolean periodicFlush();
    }

    public interface Output extends CompiledPipeline.Plugin {
        void multiReceive(RubyArray events);
    }

    public interface Pipeline {

        IRubyObject buildInput(RubyString name, IRubyObject args);

        CompiledPipeline.Output buildOutput(RubyString name, IRubyObject args);

        CompiledPipeline.Filter buildFilter(RubyString name, IRubyObject args);
    }

    private static final class FieldEquals implements CompiledPipeline.Condition {

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

    private static final class FieldMatches implements CompiledPipeline.Condition {

        private final FieldReference field;

        private final Pattern value;

        FieldMatches(final String field, final String value) {
            this.field = PathCache.cache(field);
            this.value = Pattern.compile(value);
        }

        @Override
        public boolean fulfilled(final JrubyEventExtLibrary.RubyEvent event) {
            final String tomatch = event.getEvent().getUnconvertedField(field).toString();
            return value.matcher(tomatch).find();
        }
    }

    private static final class FieldContainsListedValue implements CompiledPipeline.Condition {

        private final FieldReference field;

        private final List<?> value;

        FieldContainsListedValue(final FieldReference field, final List<?> value) {
            this.field = field;
            this.value = value;
        }

        @Override
        public boolean fulfilled(final JrubyEventExtLibrary.RubyEvent event) {
            final Object found = event.getEvent().getUnconvertedField(field);
            if (found != null) {
                return
                    value.stream().filter(val -> val.toString().equals(found.toString())).count() >
                        0L;
            } else {
                return false;
            }
        }
    }

    private static final class FieldArrayContainsValue implements CompiledPipeline.Condition {

        private final FieldReference field;

        private final String value;

        FieldArrayContainsValue(final FieldReference field, final String value) {
            this.field = field;
            this.value = value;
        }

        @Override
        public boolean fulfilled(final JrubyEventExtLibrary.RubyEvent event) {
            final Object found = event.getEvent().getUnconvertedField(field);
            if (found instanceof ConvertedList) {
                final ConvertedList tomatch = (ConvertedList) found;
                return tomatch.stream().filter(item -> item.toString().equals(value)).count() > 0L;
            } else
                return found != null && found.toString().contains(value);
        }
    }

    private static final class FieldArrayContainsFieldValue implements CompiledPipeline.Condition {

        private final FieldReference field;

        private final FieldReference value;

        FieldArrayContainsFieldValue(final FieldReference field, final FieldReference value) {
            this.field = field;
            this.value = value;
        }

        @Override
        public boolean fulfilled(final JrubyEventExtLibrary.RubyEvent event) {
            final Object found = event.getEvent().getUnconvertedField(field);
            final Object other = event.getEvent().getUnconvertedField(value);
            if (found instanceof ConvertedList && other instanceof RubyString) {
                final ConvertedList tomatch = (ConvertedList) found;
                return tomatch.stream().filter(item -> item.toString()
                    .equals(other.toString())).count() > 0L;
            } else if (found instanceof RubyString && other instanceof RubyString) {
                return found.toString().contains(other.toString());
            } else if (found instanceof RubyString && other instanceof ConvertedList) {
                final ConvertedList tomatch = (ConvertedList) other;
                return tomatch.stream().filter(item -> item.toString()
                    .equals(found.toString())).count() > 0L;
            } else {
                return found != null && other != null && found.equals(other);
            }
        }
    }

    private static final class Negated implements CompiledPipeline.Condition {

        private final CompiledPipeline.Condition condition;

        Negated(final CompiledPipeline.Condition condition) {
            this.condition = condition;
        }

        @Override
        public boolean fulfilled(final JrubyEventExtLibrary.RubyEvent event) {
            return !condition.fulfilled(event);
        }

    }
}
