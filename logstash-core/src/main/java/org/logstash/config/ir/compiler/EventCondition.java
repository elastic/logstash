package org.logstash.config.ir.compiler;

import java.util.HashMap;
import java.util.List;
import java.util.regex.Pattern;
import org.jruby.RubyString;
import org.logstash.ConvertedList;
import org.logstash.FieldReference;
import org.logstash.PathCache;
import org.logstash.RubyUtil;
import org.logstash.config.ir.expression.BinaryBooleanExpression;
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

/**
 * A pipeline execution "if" condition, compiled from the {@link BooleanExpression} of an
 * {@link org.logstash.config.ir.graph.IfVertex}.
 */
public interface EventCondition {

    boolean fulfilled(JrubyEventExtLibrary.RubyEvent event);

    final class Compiler {

        /**
         * {@link EventCondition} that is always {@code true}.
         */
        private static final EventCondition TRUE = event -> true;

        /**
         * {@link EventCondition} that is always {@code false}.
         */
        private static final EventCondition FALSE = event -> false;

        private static final HashMap<String, EventCondition> CACHE = new HashMap<>(10);

        private Compiler() {
            //Utility Class.
        }

        public static EventCondition buildCondition(final BooleanExpression expression) {
            synchronized (CACHE) {
                final String cachekey = expression.toRubyString();
                final EventCondition cached = CACHE.get(cachekey);
                if (cached != null) {
                    return cached;
                }
                final EventCondition condition;
                if (expression instanceof Eq) {
                    condition = eq((Eq) expression);
                } else if (expression instanceof RegexEq) {
                    final RegexEq regex = (RegexEq) expression;
                    if (eAndV(regex)) {
                        condition = new Compiler.FieldMatches(
                            ((EventValueExpression) regex.getLeft()).getFieldName(),
                            ((ValueExpression) regex.getRight()).get().toString()
                        );
                    } else {
                        throw new IllegalStateException("B");
                    }
                } else if (expression instanceof In) {
                    condition = in((In) expression);
                } else if (expression instanceof Or) {
                    condition = or(booleanPair((BinaryBooleanExpression) expression));
                } else if (expression instanceof Truthy) {
                    final Expression inner = ((Truthy) expression).getExpression();
                    if (inner instanceof EventValueExpression) {
                        condition = truthy((EventValueExpression) inner);
                    } else {
                        throw new IllegalStateException("GOT " + inner.getClass());
                    }
                } else if (expression instanceof Not) {
                    final Expression inner = ((Not) expression).getExpression();
                    if (inner instanceof BooleanExpression) {
                        condition = not(buildCondition((BooleanExpression) inner));
                    } else if (inner instanceof EventValueExpression) {
                        condition = not(truthy((EventValueExpression) inner));
                    } else {
                        throw new IllegalStateException("C2");
                    }
                } else if (expression instanceof Gt) {
                    condition = gt((Gt) expression);

                } else if (expression instanceof Gte) {
                    condition = gte((Gte) expression);
                } else if (expression instanceof Lt) {
                    condition = lt((Lt) expression);
                } else if (expression instanceof Lte) {
                    final Lte lessequal = (Lte) expression;
                    if (eAndV(lessequal)) {
                        condition = not(gt(
                            (EventValueExpression) lessequal.getLeft(),
                            (ValueExpression) lessequal.getRight()
                        ));
                    } else {
                        throw new IllegalStateException("F");
                    }
                } else if (expression instanceof And) {
                    condition = and(booleanPair((BinaryBooleanExpression) expression));
                } else if (expression instanceof Neq) {
                    condition = neq((Neq) expression);
                } else {
                    throw new IllegalStateException("Received " + expression.getClass());
                }
                CACHE.put(cachekey, condition);
                return condition;
            }
        }

        /**
         * Checks if a {@link BinaryBooleanExpression} consists of a {@link ValueExpression} on the
         * left and a {@link EventValueExpression} on the right.
         * @param expression Expression to check type for
         * @return True if the left branch of the {@link BinaryBooleanExpression} is a
         * {@link ValueExpression} and its right side is a {@link EventValueExpression}.
         */
        private static boolean vAndE(final BinaryBooleanExpression expression) {
            return expression.getLeft() instanceof ValueExpression &&
                expression.getRight() instanceof EventValueExpression;
        }

        private static boolean vAndV(final BinaryBooleanExpression expression) {
            return expression.getLeft() instanceof ValueExpression &&
                expression.getRight() instanceof ValueExpression;
        }

        private static boolean eAndV(final BinaryBooleanExpression expression) {
            return expression.getLeft() instanceof EventValueExpression &&
                expression.getRight() instanceof ValueExpression;
        }

        private static boolean eAndE(final BinaryBooleanExpression expression) {
            return expression.getLeft() instanceof EventValueExpression &&
                expression.getRight() instanceof EventValueExpression;
        }

        private static EventCondition neq(final Neq nequals) {
            final EventCondition condition;
            if (eAndV(nequals)) {
                condition = not(
                    eq(
                        (EventValueExpression) nequals.getLeft(),
                        (ValueExpression) nequals.getRight()
                    )
                );
            } else {
                throw new IllegalStateException("G");
            }
            return condition;
        }

        private static EventCondition gte(Gte gte) {
            final EventCondition condition;
            if (eAndV(gte)) {
                final EventValueExpression left = (EventValueExpression) gte.getLeft();
                final ValueExpression right = (ValueExpression) gte.getRight();
                condition = or(gt(left, right), eq(left, right));
            } else {
                throw new IllegalStateException("E");
            }
            return condition;
        }

        private static EventCondition lt(final Lt lt) {
            final EventCondition condition;
            if (eAndV(lt)) {
                final EventValueExpression left = (EventValueExpression) lt.getLeft();
                final ValueExpression right = (ValueExpression) lt.getRight();
                condition = not(or(gt(left, right), eq(left, right)));
            } else {
                throw new IllegalStateException("Fooo");
            }
            return condition;
        }

        private static EventCondition in(final In in) {
            final EventCondition condition;
            if (eAndV(in) && scalarValueRight(in)) {
                condition = new Compiler.FieldArrayContainsValue(
                    PathCache.cache(((EventValueExpression) in.getLeft())
                        .getFieldName()),
                    ((ValueExpression) in.getRight()).get().toString()
                );
            } else if (vAndE(in) && scalarValueLeft(in)) {
                condition = new Compiler.FieldArrayContainsValue(
                    PathCache.cache(((EventValueExpression) in.getRight())
                        .getFieldName()),
                    ((ValueExpression) in.getLeft()).get().toString()
                );
            } else if (eAndV(in) && listValueRight(in)) {
                condition = in(
                    (EventValueExpression) in.getLeft(),
                    (List<?>) ((ValueExpression) in.getRight()).get()
                );
            } else if (eAndE(in)) {
                condition = in(
                    (EventValueExpression) in.getRight(), (EventValueExpression) in.getLeft()
                );
            } else if (vAndV(in)) {
                condition = in((ValueExpression) in.getLeft(), (ValueExpression) in.getRight());
            } else {
                throw new IllegalStateException(
                    "C" + in.getRight().getClass() + " " + in.getLeft().getClass());
            }
            return condition;
        }

        private static EventCondition in(final EventValueExpression left, final List<?> right) {
            return new Compiler.FieldContainsListedValue(
                PathCache.cache(left.getFieldName()), right
            );
        }

        private static EventCondition in(final ValueExpression left, final ValueExpression right) {
            final Object found = right.get();
            final Object other = left.get();
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
        }

        private static boolean listValueRight(final In in) {
            return ((ValueExpression) in.getRight()).get() instanceof List;
        }

        private static boolean scalarValueRight(final In in) {
            return (((ValueExpression) in.getRight()).get() instanceof String
                || ((ValueExpression) in.getRight()).get() instanceof Number);
        }

        private static boolean scalarValueLeft(final In in) {
            return (((ValueExpression) in.getLeft()).get() instanceof String
                || ((ValueExpression) in.getLeft()).get() instanceof Number);
        }

        private static EventCondition in(final EventValueExpression left,
            final EventValueExpression right) {
            return new Compiler.FieldArrayContainsFieldValue(
                PathCache.cache(left.getFieldName()), PathCache.cache(right.getFieldName())
            );
        }

        private static EventCondition eq(final EventValueExpression evale,
            final ValueExpression vale) {
            return new Compiler.FieldEquals(
                evale.getFieldName(), vale.get().toString()
            );
        }

        private static EventCondition eq(final Eq equals) {
            final EventCondition condition;
            if (eAndV(equals)) {
                condition = eq(
                    (EventValueExpression) equals.getLeft(), (ValueExpression) equals.getRight()
                );
            } else if (eAndE(equals)) {
                condition = eq(
                    (EventValueExpression) equals.getLeft(),
                    (EventValueExpression) equals.getRight()
                );
            } else {
                throw new IllegalStateException("A");
            }
            return condition;
        }

        private static EventCondition eq(final EventValueExpression first,
            final EventValueExpression second) {
            return new Compiler.FieldEqualsField(
                PathCache.cache(first.getFieldName()), PathCache.cache(second.getFieldName())
            );
        }

        private static EventCondition gt(final Gt greater) {
            final EventCondition condition;
            if (eAndV(greater)) {
                condition = gt(
                    (EventValueExpression) greater.getLeft(),
                    (ValueExpression) greater.getRight()
                );
            } else {
                throw new IllegalStateException("D");
            }
            return condition;
        }

        private static EventCondition gt(final EventValueExpression left,
            final ValueExpression right) {
            return new Compiler.FieldGreaterThan(
                left.getFieldName(),
                right.get().toString()
            );
        }

        private static EventCondition truthy(final EventValueExpression evale) {
            return new Compiler.FieldTruthy(PathCache.cache(evale.getFieldName()));
        }

        private static EventCondition[] booleanPair(final BinaryBooleanExpression expression) {
            final Expression left = expression.getLeft();
            final Expression right = expression.getRight();
            final EventCondition first;
            final EventCondition second;
            if (left instanceof BooleanExpression && right instanceof BooleanExpression) {
                first = buildCondition((BooleanExpression) left);
                second = buildCondition((BooleanExpression) right);
            } else if (eAndE(expression)) {
                first = truthy((EventValueExpression) left);
                second = truthy((EventValueExpression) right);
            } else if (left instanceof BooleanExpression && right instanceof EventValueExpression) {
                first = buildCondition((BooleanExpression) left);
                second = truthy((EventValueExpression) right);
            } else if (right instanceof BooleanExpression &&
                left instanceof EventValueExpression) {
                first = truthy((EventValueExpression) left);
                second = buildCondition((BooleanExpression) right);
            } else {
                throw new IllegalArgumentException(
                    String.format(
                        "Unexpected input types %s %s", left.getClass(), right.getClass())
                );
            }
            return new EventCondition[]{first, second};
        }

        public static EventCondition not(final EventCondition condition) {
            return new Compiler.Negated(condition);
        }

        private static EventCondition or(EventCondition... conditions) {
            return new Compiler.OrCondition(conditions[0], conditions[1]);
        }

        private static EventCondition and(EventCondition... conditions) {
            return new Compiler.AndCondition(conditions[0], conditions[1]);
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
                final Object val = event.getEvent().getUnconvertedField(field);
                return val != null && value.toString().equals(val.toString());
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

        private static final class FieldTruthy implements EventCondition {

            private final FieldReference field;

            private FieldTruthy(final FieldReference field) {
                this.field = field;
            }

            @Override
            public boolean fulfilled(final JrubyEventExtLibrary.RubyEvent event) {
                final Object object = event.getEvent().getUnconvertedField(field);
                if (object == null) {
                    return false;
                }
                final String string = object.toString();
                return string != null && !string.isEmpty() &&
                    !Boolean.toString(false).equals(string);
            }
        }
    }
}
