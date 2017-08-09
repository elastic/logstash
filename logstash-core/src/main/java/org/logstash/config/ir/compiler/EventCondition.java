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
import org.logstash.config.ir.expression.Expression;
import org.logstash.config.ir.expression.ValueExpression;
import org.logstash.config.ir.expression.binary.And;
import org.logstash.config.ir.expression.binary.Eq;
import org.logstash.config.ir.expression.binary.Gt;
import org.logstash.config.ir.expression.binary.Gte;
import org.logstash.config.ir.expression.binary.In;
import org.logstash.config.ir.expression.binary.Lt;
import org.logstash.config.ir.expression.binary.Lte;
import org.logstash.config.ir.expression.binary.Neq;
import org.logstash.config.ir.expression.binary.Or;
import org.logstash.config.ir.expression.binary.RegexEq;
import org.logstash.config.ir.expression.unary.Not;
import org.logstash.config.ir.expression.unary.Truthy;
import org.logstash.ext.JrubyEventExtLibrary;

public interface EventCondition {

    boolean fulfilled(JrubyEventExtLibrary.RubyEvent event);

    final class Factory {

        private static final EventCondition TRUE = event -> true;

        private static final EventCondition FALSE = event -> false;

        private Factory() {
        }

        public static EventCondition not(final EventCondition condition) {
            return new EventCondition.Factory.Negated(condition);
        }

        public static EventCondition or(final EventCondition first, final EventCondition second) {
            return new EventCondition.Factory.OrCondition(first, second);
        }

        public static EventCondition and(final EventCondition first, final EventCondition second) {
            return new EventCondition.Factory.AndCondition(first, second);
        }

        public static EventCondition buildCondition(final BooleanExpression expression) {
            final EventCondition condition;
            if (expression instanceof Eq) {
                final Eq equals = (Eq) expression;
                if (equals.getLeft() instanceof EventValueExpression &&
                    equals.getRight() instanceof ValueExpression) {
                    condition = new EventCondition.Factory.FieldEquals(
                        ((EventValueExpression) equals.getLeft())
                            .getFieldName(),
                        ((ValueExpression) equals.getRight()).get().toString()
                    );
                } else if (equals.getLeft() instanceof EventValueExpression &&
                    equals.getRight() instanceof EventValueExpression) {
                    condition = new EventCondition.Factory.FieldEqualsField(
                        PathCache.cache(((EventValueExpression) equals.getLeft()).getFieldName()),
                        PathCache.cache(((EventValueExpression) equals.getRight()).getFieldName())
                    );
                } else {
                    throw new IllegalStateException("A");
                }
            } else if (expression instanceof RegexEq) {
                final RegexEq regex = (RegexEq) expression;
                if (regex.getLeft() instanceof EventValueExpression &&
                    regex.getRight() instanceof ValueExpression) {
                    condition = new EventCondition.Factory.FieldMatches(
                        ((EventValueExpression) regex.getLeft()).getFieldName(),
                        ((ValueExpression) regex.getRight()).get().toString()
                    );
                } else {
                    throw new IllegalStateException("B");
                }
            } else if (expression instanceof In) {
                final In in = (In) expression;
                if (in.getLeft() instanceof EventValueExpression &&
                    in.getRight() instanceof ValueExpression
                    &&
                    (((ValueExpression) in.getRight()).get() instanceof String
                        || ((ValueExpression) in.getRight())
                        .get() instanceof Number)) {
                    condition = new EventCondition.Factory.FieldArrayContainsValue(
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
                    condition = new EventCondition.Factory.FieldArrayContainsValue(
                        PathCache.cache(((EventValueExpression) in.getRight())
                            .getFieldName()),
                        ((ValueExpression) in.getLeft()).get().toString()
                    );
                } else if (in.getLeft() instanceof EventValueExpression &&
                    in.getRight() instanceof ValueExpression
                    &&
                    ((ValueExpression) in.getRight()).get() instanceof List) {
                    condition = new EventCondition.Factory.FieldContainsListedValue(
                        PathCache.cache(((EventValueExpression) in.getLeft())
                            .getFieldName()),
                        (List<?>) ((ValueExpression) in.getRight()).get()
                    );
                } else if (in.getRight() instanceof EventValueExpression &&
                    in.getLeft() instanceof ValueExpression
                    &&
                    ((ValueExpression) in.getLeft()).get() instanceof List) {
                    condition = new EventCondition.Factory.FieldContainsListedValue(
                        PathCache.cache(((EventValueExpression) in.getRight())
                            .getFieldName()),
                        (List) ((ValueExpression) in.getLeft()).get()
                    );
                } else if (in.getRight() instanceof EventValueExpression &&
                    in.getLeft() instanceof EventValueExpression) {
                    condition =
                        new EventCondition.Factory.FieldArrayContainsFieldValue(
                            PathCache
                                .cache(((EventValueExpression) in.getRight())
                                    .getFieldName()),
                            PathCache
                                .cache(((EventValueExpression) in.getLeft())
                                    .getFieldName())
                        );
                } else if (in.getRight() instanceof ValueExpression &&
                    in.getLeft() instanceof ValueExpression) {
                    final Object found = ((ValueExpression) in.getRight()).get();
                    final Object other = ((ValueExpression) in.getLeft()).get();
                    if (found instanceof ConvertedList && other instanceof RubyString) {
                        return ((ConvertedList) found).stream().filter(item -> item.toString()
                            .equals(other.toString())).count() > 0L ? TRUE : FALSE;
                    } else if (found instanceof RubyString && other instanceof RubyString) {
                        return found.toString().contains(other.toString()) ? TRUE : FALSE;
                    } else if (found instanceof RubyString && other instanceof ConvertedList) {
                        return ((ConvertedList) other).stream()
                            .filter(item -> item.toString().equals(found.toString())).count() >
                            0L ? TRUE : FALSE;
                    } else {
                        return found != null && other != null && found.equals(other) ? TRUE : FALSE;
                    }
                } else {
                    throw new IllegalStateException(
                        "C" + in.getRight().getClass() + " " + in.getLeft().getClass());
                }
            } else if (expression instanceof Or) {
                final Or or = (Or) expression;
                final Expression left = or.getLeft();
                final Expression right = or.getRight();
                final EventCondition first;
                final EventCondition second;
                if (left instanceof BooleanExpression && right instanceof BooleanExpression) {
                    first = buildCondition((BooleanExpression) left);
                    second = buildCondition((BooleanExpression) right);
                } else if (left instanceof EventValueExpression && right instanceof EventValueExpression) {
                    final FieldReference lfield =
                        PathCache.cache(((EventValueExpression) left).getFieldName());
                    final FieldReference rfield =
                        PathCache.cache(((EventValueExpression) left).getFieldName());
                    first = event -> event.getEvent().getUnconvertedField(lfield).equals(true);
                    second = event -> event.getEvent().getUnconvertedField(rfield).equals(true);
                } else if (left instanceof BooleanExpression && right instanceof EventValueExpression) {
                    final FieldReference rfield =
                        PathCache.cache(((EventValueExpression) right).getFieldName());
                    second = event -> event.getEvent().getUnconvertedField(rfield).equals(true);
                    first = buildCondition((BooleanExpression) left);
                } else if (right instanceof BooleanExpression && left instanceof EventValueExpression) {
                    final FieldReference lfield =
                        PathCache.cache(((EventValueExpression) left).getFieldName());
                    first = event -> event.getEvent().getUnconvertedField(lfield).equals(true);
                    second = buildCondition((BooleanExpression) right);
                } else {
                    throw new IllegalStateException(
                        "GOT " + left.getClass() + " " + right.getClass());
                }
                condition = or(first, second);
            } else if (expression instanceof Truthy) {
                condition = TRUE;
            } else if (expression instanceof Not) {
                final Expression inner = ((Not) expression).getExpression();
                if (inner instanceof BooleanExpression) {
                    condition = not(buildCondition((BooleanExpression) inner));
                } else if (inner instanceof EventValueExpression) {
                    final FieldReference field =
                        PathCache.cache(((EventValueExpression) inner).getFieldName());
                    condition = not(
                        event -> event.getEvent().getUnconvertedField(field).equals(true)
                    );
                } else {
                    throw new IllegalStateException("C2");
                }
            } else if (expression instanceof Gt) {
                final Gt greater = (Gt) expression;
                if (greater.getLeft() instanceof EventValueExpression &&
                    greater.getRight() instanceof ValueExpression) {
                    condition = new EventCondition.Factory.FieldGreaterThan(
                        ((EventValueExpression) greater.getLeft())
                            .getFieldName(),
                        ((ValueExpression) greater.getRight()).get().toString()
                    );
                } else {
                    throw new IllegalStateException("D");
                }
            } else if (expression instanceof Gte) {
                final Gte gre = (Gte) expression;
                if (gre.getLeft() instanceof EventValueExpression &&
                    gre.getRight() instanceof ValueExpression) {
                    condition = or(new EventCondition.Factory.FieldGreaterThan(
                        ((EventValueExpression) gre.getLeft())
                            .getFieldName(),
                        ((ValueExpression) gre.getRight()).get().toString()
                    ), new EventCondition.Factory.FieldEquals(
                        ((EventValueExpression) gre.getLeft())
                            .getFieldName(),
                        ((ValueExpression) gre.getRight()).get().toString()
                    ));
                } else {
                    throw new IllegalStateException("E");
                }
            } else if (expression instanceof Lt) {
                final Lt lt = (Lt) expression;
                if (lt.getLeft() instanceof EventValueExpression &&
                    lt.getRight() instanceof ValueExpression) {
                    condition = not(or(new EventCondition.Factory.FieldGreaterThan(
                        ((EventValueExpression) lt.getLeft())
                            .getFieldName(),
                        ((ValueExpression) lt.getRight()).get().toString()
                    ), new EventCondition.Factory.FieldEquals(
                        ((EventValueExpression) lt.getLeft())
                            .getFieldName(),
                        ((ValueExpression) lt.getRight()).get().toString()
                    )));
                } else {
                    throw new IllegalStateException("Fooo");
                }
            } else if (expression instanceof Lte) {
                final Lte lessequal = (Lte) expression;
                if (lessequal.getLeft() instanceof EventValueExpression &&
                    lessequal.getRight() instanceof ValueExpression) {
                    condition = not(new EventCondition.Factory.FieldGreaterThan(
                        ((EventValueExpression) lessequal.getLeft())
                            .getFieldName(),
                        ((ValueExpression) lessequal.getRight()).get().toString()
                    ));
                } else {
                    throw new IllegalStateException("F");
                }
            } else if (expression instanceof And) {
                final And and = (And) expression;
                final Expression left = and.getLeft();
                final Expression right = and.getRight();
                final EventCondition first;
                final EventCondition second;
                if (left instanceof BooleanExpression && right instanceof BooleanExpression) {
                    first = buildCondition((BooleanExpression) left);
                    second = buildCondition((BooleanExpression) right);
                } else if (left instanceof EventValueExpression && right instanceof EventValueExpression) {
                    final FieldReference lfield =
                        PathCache.cache(((EventValueExpression) left).getFieldName());
                    final FieldReference rfield =
                        PathCache.cache(((EventValueExpression) left).getFieldName());
                    first = event -> event.getEvent().getUnconvertedField(lfield).equals(true);
                    second = event -> event.getEvent().getUnconvertedField(rfield).equals(true);
                } else if (left instanceof BooleanExpression && right instanceof EventValueExpression) {
                    final FieldReference rfield =
                        PathCache.cache(((EventValueExpression) right).getFieldName());
                    second = event -> event.getEvent().getUnconvertedField(rfield).equals(true);
                    first = buildCondition((BooleanExpression) left);
                } else if (right instanceof BooleanExpression && left instanceof EventValueExpression) {
                    final FieldReference lfield =
                        PathCache.cache(((EventValueExpression) left).getFieldName());
                    first = event -> event.getEvent().getUnconvertedField(lfield).equals(true);
                    second = buildCondition((BooleanExpression) right);
                } else {
                    throw new IllegalStateException(
                        "GOT " + left.getClass() + " " + right.getClass());
                }
                condition = and(first, second);
            } else if (expression instanceof Neq) {
                final Neq nequals = (Neq) expression;
                if (nequals.getLeft() instanceof EventValueExpression &&
                    nequals.getRight() instanceof ValueExpression) {
                    condition = not(new EventCondition.Factory.FieldEquals(
                            ((EventValueExpression) nequals.getLeft())
                                .getFieldName(),
                            ((ValueExpression) nequals.getRight()).get().toString()
                        )
                    );
                } else {
                    throw new IllegalStateException("G");
                }
            } else {
                throw new IllegalStateException("Received " + expression.getClass());
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

        private static final class AndCondition implements EventCondition {

            private final EventCondition first;

            private final EventCondition second;

            AndCondition(final EventCondition first, final EventCondition second) {
                this.first = first;
                this.second = second;
            }

            @Override
            public boolean fulfilled(final JrubyEventExtLibrary.RubyEvent event) {
                return first.fulfilled(event) && second.fulfilled(event);
            }

        }

        private static final class OrCondition implements EventCondition {

            private final EventCondition first;

            private final EventCondition second;

            OrCondition(final EventCondition first, final EventCondition second) {
                this.first = first;
                this.second = second;
            }

            @Override
            public boolean fulfilled(final JrubyEventExtLibrary.RubyEvent event) {
                return first.fulfilled(event) || second.fulfilled(event);
            }

        }

        private static final class FieldGreaterThan implements EventCondition {

            private final FieldReference field;

            private final RubyString value;

            private FieldGreaterThan(final String field, final String value) {
                this.field = PathCache.cache(field);
                this.value = RubyUtil.RUBY.newString(value);
            }

            @Override
            public boolean fulfilled(final JrubyEventExtLibrary.RubyEvent event) {
                return value.toString()
                    .compareTo(event.getEvent().getUnconvertedField(field).toString()) < 0;
            }
        }

        private static final class FieldEquals implements EventCondition {

            private final FieldReference field;

            private final RubyString value;

            private FieldEquals(final String field, final String value) {
                this.field = PathCache.cache(field);
                this.value = RubyUtil.RUBY.newString(value);
            }

            @Override
            public boolean fulfilled(final JrubyEventExtLibrary.RubyEvent event) {
                return value.equals(event.getEvent().getUnconvertedField(field));
            }
        }

        private static final class FieldEqualsField implements EventCondition {

            private final FieldReference one;

            private final FieldReference other;

            private FieldEqualsField(final FieldReference one, final FieldReference other) {
                this.one = one;
                this.other = other;
            }

            @Override
            public boolean fulfilled(final JrubyEventExtLibrary.RubyEvent event) {
                return event.getEvent().getUnconvertedField(one)
                    .equals(event.getEvent().getUnconvertedField(other));
            }
        }

        private static final class FieldMatches implements EventCondition {

            private final FieldReference field;

            private final Pattern value;

            private FieldMatches(final String field, final String value) {
                this.field = PathCache.cache(field);
                this.value = Pattern.compile(value);
            }

            @Override
            public boolean fulfilled(final JrubyEventExtLibrary.RubyEvent event) {
                final String tomatch = event.getEvent().getUnconvertedField(field).toString();
                return value.matcher(tomatch).find();
            }
        }

        private static final class FieldArrayContainsValue implements EventCondition {

            private final FieldReference field;

            private final String value;

            private FieldArrayContainsValue(final FieldReference field, final String value) {
                this.field = field;
                this.value = value;
            }

            @Override
            public boolean fulfilled(final JrubyEventExtLibrary.RubyEvent event) {
                final Object found = event.getEvent().getUnconvertedField(field);
                if (found instanceof ConvertedList) {
                    return ((ConvertedList) found).stream()
                        .filter(item -> item.toString().equals(value)).count() > 0L;
                } else
                    return found != null && found.toString().contains(value);
            }
        }

        private static final class FieldArrayContainsFieldValue implements EventCondition {

            private final FieldReference field;

            private final FieldReference value;

            private FieldArrayContainsFieldValue(final FieldReference field,
                final FieldReference value) {
                this.field = field;
                this.value = value;
            }

            @Override
            public boolean fulfilled(final JrubyEventExtLibrary.RubyEvent event) {
                final Object found = event.getEvent().getUnconvertedField(field);
                final Object other = event.getEvent().getUnconvertedField(value);
                if (found instanceof ConvertedList && other instanceof RubyString) {
                    return ((ConvertedList) found).stream().filter(item -> item.toString()
                        .equals(other.toString())).count() > 0L;
                } else if (found instanceof RubyString && other instanceof RubyString) {
                    return found.toString().contains(other.toString());
                } else if (found instanceof RubyString && other instanceof ConvertedList) {
                    return ((ConvertedList) other).stream()
                        .filter(item -> item.toString().equals(found.toString())).count() > 0L;
                } else {
                    return found != null && other != null && found.equals(other);
                }
            }
        }

        private static final class FieldContainsListedValue implements EventCondition {

            private final FieldReference field;

            private final List<?> value;

            private FieldContainsListedValue(final FieldReference field, final List<?> value) {
                this.field = field;
                this.value = value;
            }

            @Override
            public boolean fulfilled(final JrubyEventExtLibrary.RubyEvent event) {
                final Object found = event.getEvent().getUnconvertedField(field);
                return found != null &&
                    value.stream().filter(val -> val.toString().equals(found.toString())).count() >
                        0L;
            }
        }
    }
}
