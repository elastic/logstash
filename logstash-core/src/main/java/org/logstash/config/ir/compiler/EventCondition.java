package org.logstash.config.ir.compiler;

import java.util.List;
import java.util.regex.Pattern;
import org.jruby.RubyString;
import org.logstash.ConvertedList;
import org.logstash.FieldReference;
import org.logstash.PathCache;
import org.logstash.RubyUtil;
import org.logstash.config.ir.expression.BooleanExpression;
import org.logstash.config.ir.expression.EventValueExpression;
import org.logstash.config.ir.expression.ValueExpression;
import org.logstash.config.ir.expression.binary.Eq;
import org.logstash.config.ir.expression.binary.In;
import org.logstash.config.ir.expression.binary.RegexEq;
import org.logstash.ext.JrubyEventExtLibrary;

public interface EventCondition {

    boolean fulfilled(JrubyEventExtLibrary.RubyEvent event);

    final class Factory {

        public static EventCondition not(final EventCondition condition) {
            return new EventCondition.Factory.Negated(condition);
        }

        public static EventCondition buildCondition(final BooleanExpression expression) {
            EventCondition condition = null;
            if (expression instanceof Eq) {
                final Eq equals = (Eq) expression;
                if (equals.getLeft() instanceof EventValueExpression &&
                    equals.getRight() instanceof ValueExpression) {
                    condition = new FieldEquals(
                        ((EventValueExpression) equals.getLeft())
                            .getFieldName(),
                        ((ValueExpression) equals.getRight()).get().toString()
                    );
                }
            } else if (expression instanceof RegexEq) {
                final RegexEq regex = (RegexEq) expression;
                if (regex.getLeft() instanceof EventValueExpression &&
                    regex.getRight() instanceof ValueExpression) {
                    condition = new FieldMatches(
                        ((EventValueExpression) regex.getLeft()).getFieldName(),
                        ((ValueExpression) regex.getRight()).get().toString()
                    );
                }
            } else if (expression instanceof In) {
                final In in = (In) expression;
                if (in.getLeft() instanceof EventValueExpression &&
                    in.getRight() instanceof ValueExpression
                    &&
                    (((ValueExpression) in.getRight()).get() instanceof String
                        || ((ValueExpression) in.getRight())
                        .get() instanceof Number)) {
                    condition = new FieldArrayContainsValue(
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
                    condition = new FieldArrayContainsValue(
                        PathCache.cache(((EventValueExpression) in.getRight())
                            .getFieldName()),
                        ((ValueExpression) in.getLeft()).get().toString()
                    );
                } else if (in.getLeft() instanceof EventValueExpression &&
                    in.getRight() instanceof ValueExpression
                    &&
                    ((ValueExpression) in.getRight()).get() instanceof List) {
                    condition = new FieldContainsListedValue(
                        PathCache.cache(((EventValueExpression) in.getLeft())
                            .getFieldName()),
                        (List<?>) ((ValueExpression) in.getRight()).get()
                    );
                } else if (in.getRight() instanceof EventValueExpression &&
                    in.getLeft() instanceof ValueExpression
                    &&
                    ((ValueExpression) in.getLeft()).get() instanceof List) {
                    condition = new FieldContainsListedValue(
                        PathCache.cache(((EventValueExpression) in.getRight())
                            .getFieldName()),
                        (List) ((ValueExpression) in.getLeft()).get()
                    );
                } else if (in.getRight() instanceof EventValueExpression &&
                    in.getLeft() instanceof EventValueExpression) {
                    condition =
                        new FieldArrayContainsFieldValue(
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

        private static final class Negated implements EventCondition {

            private final EventCondition condition;

            Negated(final EventCondition condition) {
                this.condition = condition;
            }

            @Override
            public boolean fulfilled(final JrubyEventExtLibrary.RubyEvent event) {
                return !condition.fulfilled(event);
            }

        }
    }

    final class FieldEquals implements EventCondition {

        private final FieldReference field;

        private final RubyString value;

        public FieldEquals(final String field, final String value) {
            this.field = PathCache.cache(field);
            this.value = RubyUtil.RUBY.newString(value);
        }

        @Override
        public boolean fulfilled(final JrubyEventExtLibrary.RubyEvent event) {
            return value.equals(event.getEvent().getUnconvertedField(field));
        }
    }

    final class FieldMatches implements EventCondition {

        private final FieldReference field;

        private final Pattern value;

        public FieldMatches(final String field, final String value) {
            this.field = PathCache.cache(field);
            this.value = Pattern.compile(value);
        }

        @Override
        public boolean fulfilled(final JrubyEventExtLibrary.RubyEvent event) {
            final String tomatch = event.getEvent().getUnconvertedField(field).toString();
            return value.matcher(tomatch).find();
        }
    }

    final class FieldArrayContainsValue implements EventCondition {

        private final FieldReference field;

        private final String value;

        public FieldArrayContainsValue(final FieldReference field, final String value) {
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

    final class FieldArrayContainsFieldValue implements EventCondition {

        private final FieldReference field;

        private final FieldReference value;

        public FieldArrayContainsFieldValue(final FieldReference field,
            final FieldReference value) {
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

    final class FieldContainsListedValue implements EventCondition {

        private final FieldReference field;

        private final List<?> value;

        public FieldContainsListedValue(final FieldReference field, final List<?> value) {
            this.field = field;
            this.value = value;
        }

        @Override
        public boolean fulfilled(final JrubyEventExtLibrary.RubyEvent event) {
            final Object found = event.getEvent().getUnconvertedField(field);
            return found != null &&
                value.stream().filter(val -> val.toString().equals(found.toString())).count() > 0L;
        }
    }
}
