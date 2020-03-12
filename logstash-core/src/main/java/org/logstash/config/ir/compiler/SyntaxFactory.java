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


package org.logstash.config.ir.compiler;

import java.util.Arrays;
import java.util.Collection;
import java.util.Objects;
import java.util.stream.Collectors;

/**
 * Utility class for setting up various {@link SyntaxElement}.
 */
final class SyntaxFactory {

    /**
     * Joins given {@link String}s without delimiter.
     * @param parts Strings to join
     * @return Strings join without delimiter
     */
    public static String join(final String... parts) {
        return String.join("", parts);
    }

    public static MethodLevelSyntaxElement ret(final MethodLevelSyntaxElement value) {
        return new SyntaxFactory.ReturnStatement(value);
    }

    public static ValueSyntaxElement value(final String value) {
        return new SyntaxFactory.ValueStatement(value);
    }

    public static SyntaxFactory.IdentifierStatement identifier(final String name) {
        return new SyntaxFactory.IdentifierStatement(name);
    }

    public static ValueSyntaxElement constant(final Class<?> clazz,
        final String name) {
        return new SyntaxFactory.ValueStatement(
            join(clazz.getName(), ".", name));
    }

    public static MethodLevelSyntaxElement assignment(final SyntaxElement target,
        final MethodLevelSyntaxElement value) {
        return new SyntaxFactory.Assignment(target, value);
    }

    public static ValueSyntaxElement cast(final Class<?> clazz, final ValueSyntaxElement argument) {
        return new SyntaxFactory.TypeCastStatement(clazz, argument);
    }

    public static MethodLevelSyntaxElement and(final ValueSyntaxElement left,
        final ValueSyntaxElement right) {
        return () -> join("(", left.generateCode(), "&&", right.generateCode(), ")");
    }

    public static ValueSyntaxElement ternary(final ValueSyntaxElement condition,
        final ValueSyntaxElement left, final ValueSyntaxElement right) {
        return new SyntaxFactory.TernaryStatement(condition, left, right);
    }

    public static MethodLevelSyntaxElement not(final ValueSyntaxElement var) {
        return () -> join("!(", var.generateCode(), ")");
    }

    public static MethodLevelSyntaxElement forLoop(final VariableDefinition element,
        final MethodLevelSyntaxElement iterable, final Closure body) {
        return () -> join(
            "for (", element.generateCode(), " : ",
            iterable.generateCode(), ") {\n", body.generateCode(), "\n}"
        );
    }

    public static MethodLevelSyntaxElement ifCondition(final MethodLevelSyntaxElement condition,
        final Closure body) {
        return ifCondition(condition, body, Closure.EMPTY);
    }

    public static MethodLevelSyntaxElement ifCondition(final MethodLevelSyntaxElement condition,
        final Closure left, final Closure right) {
        return () -> join(
            "if(", condition.generateCode(), ") {\n", left.generateCode(),
            "\n}",
            right.empty() ? "" : join(" else {\n", right.generateCode(), "\n}")
        );
    }

    public static final class IdentifierStatement implements ValueSyntaxElement {

        private final String value;

        private IdentifierStatement(final String value) {
            this.value = value;
        }

        @Override
        public String generateCode() {
            return value;
        }
    }

    /**
     * An assignment, renders {@code target = value}.
     */
    private static final class Assignment implements MethodLevelSyntaxElement {

        private final SyntaxElement field;

        private final MethodLevelSyntaxElement value;

        private Assignment(final SyntaxElement field, final MethodLevelSyntaxElement value) {
            this.field = field;
            this.value = value;
        }

        @Override
        public String generateCode() {
            return join(field.generateCode(), "=", value.generateCode());
        }
    }

    /**
     * A object value that can be assigned to and call methods on.
     */
    private static final class ValueStatement implements ValueSyntaxElement {

        private final String value;

        private ValueStatement(final String value) {
            this.value = value;
        }

        @Override
        public String generateCode() {
            return value;
        }

        @Override
        public boolean equals(final Object other) {
            if (this == other) {
                return true;
            }
            if (!(other instanceof SyntaxFactory.ValueStatement)) {
                return false;
            }
            return this.value.equals(((SyntaxFactory.ValueStatement) other).value);
        }

        @Override
        public int hashCode() {
            return value.hashCode();
        }
    }

    /**
     * The result of an instance method call.
     */
    static final class MethodCallReturnValue implements ValueSyntaxElement {

        /**
         * Instance to call method on.
         */
        private final MethodLevelSyntaxElement instance;

        /**
         * Name of method.
         */
        private final String method;

        /**
         * Arguments to pass to method.
         */
        private final Collection<MethodLevelSyntaxElement> args;

        MethodCallReturnValue(final MethodLevelSyntaxElement instance, final String method,
            final MethodLevelSyntaxElement... args) {
            this.instance = instance;
            this.args = Arrays.asList(args);
            this.method = method;
        }

        @Override
        public String generateCode() {
            return join(
                instance.generateCode(), ".", method, "(", String.join(
                    ",",
                    args.stream().map(SyntaxElement::generateCode).collect(Collectors.toList())
                ), ")"
            );
        }

        @Override
        public boolean equals(final Object other) {
            if (this == other) {
                return true;
            }
            if (!(other instanceof SyntaxFactory.MethodCallReturnValue)) {
                return false;
            }
            final SyntaxFactory.MethodCallReturnValue that =
                (SyntaxFactory.MethodCallReturnValue) other;
            return this.instance.equals(that.instance) && this.method.equals(that.method)
                && this.args.size() == that.args.size() && this.args.containsAll(that.args);
        }

        @Override
        public int hashCode() {
            return Objects.hash(instance, method, args);
        }
    }

    private static final class TypeCastStatement implements ValueSyntaxElement {

        private final Class<?> clazz;

        private final ValueSyntaxElement argument;

        private TypeCastStatement(final Class<?> clazz, final ValueSyntaxElement argument) {
            this.clazz = clazz;
            this.argument = argument;
        }

        @Override
        public String generateCode() {
            return join("((", clazz.getName(), ")", argument.generateCode(), ")");
        }
    }

    private static final class ReturnStatement implements MethodLevelSyntaxElement {

        private final MethodLevelSyntaxElement value;

        private ReturnStatement(final MethodLevelSyntaxElement value) {
            this.value = value;
        }

        @Override
        public String generateCode() {
            return join("return ", value.generateCode());
        }
    }

    private static final class TernaryStatement implements ValueSyntaxElement {

        private final ValueSyntaxElement left;

        private final ValueSyntaxElement right;

        private final ValueSyntaxElement condition;

        private TernaryStatement(final ValueSyntaxElement condition,
            final ValueSyntaxElement left, final ValueSyntaxElement right) {
            this.condition = condition;
            this.left = left;
            this.right = right;
        }

        @Override
        public String generateCode() {
            return join(
                "(", condition.generateCode(), " ? ", left.generateCode(), " : ",
                right.generateCode(), ")"
            );
        }
    }
}
