package org.logstash.config.ir.compiler;

import java.util.Arrays;
import java.util.Collection;
import java.util.stream.Collectors;

/**
 * Utility class for setting up various {@link SyntaxElement}.
 */
final class SyntaxFactory {

    public static final SyntaxFactory.IdentifierStatement THIS = identifier("this");

    public static final SyntaxFactory.IdentifierStatement TRUE = identifier("true");

    public static final SyntaxFactory.IdentifierStatement FALSE = identifier("false");

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

    public static ValueSyntaxElement arrayField(final MethodLevelSyntaxElement array,
        final int index) {
        return new ValueSyntaxElement() {
            @Override
            public MethodLevelSyntaxElement replace(final MethodLevelSyntaxElement search,
                final MethodLevelSyntaxElement replacement) {
                return arrayField(array.replace(search, replacement), index);
            }

            @Override
            public int count(final MethodLevelSyntaxElement search) {
                return array.count(search);
            }

            @Override
            public String generateCode() {
                return join(array.generateCode(), String.format("[%d]", index));
            }
        };
    }

    public static MethodLevelSyntaxElement assignment(final SyntaxElement target,
        final MethodLevelSyntaxElement value) {
        return new SyntaxFactory.Assignment(target, value);
    }

    public static MethodLevelSyntaxElement definition(final VariableDefinition declaration,
        final MethodLevelSyntaxElement value) {
        return new SyntaxFactory.Assignment(declaration, value);
    }

    public static ValueSyntaxElement cast(final Class<?> clazz, final ValueSyntaxElement argument) {
        return new SyntaxFactory.TypeCastStatement(clazz, argument);
    }

    public static MethodLevelSyntaxElement and(final ValueSyntaxElement left,
        final ValueSyntaxElement right) {
        return new MethodLevelSyntaxElement() {

            @Override
            public String generateCode() {
                return join("(", left.generateCode(), "&&", right.generateCode(), ")");
            }

            @Override
            public MethodLevelSyntaxElement replace(final MethodLevelSyntaxElement search,
                final MethodLevelSyntaxElement replacement) {
                return and(
                    (ValueSyntaxElement) left.replace(search, replacement),
                    (ValueSyntaxElement) right.replace(search, replacement)
                );
            }

            @Override
            public int count(final MethodLevelSyntaxElement search) {
                return left.count(search) + right.count(search);
            }
        };
    }

    public static ValueSyntaxElement ternary(final ValueSyntaxElement condition,
        final ValueSyntaxElement left, final ValueSyntaxElement right) {
        return new SyntaxFactory.TernaryStatement(condition, left, right);
    }

    public static MethodLevelSyntaxElement not(final ValueSyntaxElement var) {
        return new MethodLevelSyntaxElement() {
            @Override
            public MethodLevelSyntaxElement replace(final MethodLevelSyntaxElement search,
                final MethodLevelSyntaxElement replacement) {
                return not((ValueSyntaxElement) var.replace(search, replacement));
            }

            @Override
            public int count(final MethodLevelSyntaxElement search) {
                return var.count(search);
            }

            @Override
            public String generateCode() {
                return join("!(", var.generateCode(), ")");
            }
        };
    }

    public static MethodLevelSyntaxElement forLoop(final VariableDefinition element,
        final MethodLevelSyntaxElement iterable, final Closure body) {
        return new MethodLevelSyntaxElement() {
            @Override
            public MethodLevelSyntaxElement replace(final MethodLevelSyntaxElement search,
                final MethodLevelSyntaxElement replacement) {
                return forLoop(
                    element, iterable.replace(search, replacement),
                    (Closure) body.replace(search, replacement)
                );
            }

            @Override
            public int count(final MethodLevelSyntaxElement search) {
                return iterable.count(search) + iterable.count(search);
            }

            @Override
            public String generateCode() {
                return join(
                    "for (", element.generateCode(), " : ",
                    iterable.generateCode(), ") {\n", body.generateCode(), "\n}"
                );
            }
        };
    }

    public static MethodLevelSyntaxElement ifCondition(final MethodLevelSyntaxElement condition,
        final Closure body) {
        return ifCondition(condition, body, Closure.EMPTY);
    }

    public static MethodLevelSyntaxElement ifCondition(final MethodLevelSyntaxElement condition,
        final Closure left, final Closure right) {
        return new MethodLevelSyntaxElement() {
            @Override
            public String generateCode() {
                return join(
                    "if(", condition.generateCode(), ") {\n", left.generateCode(),
                    "\n}",
                    right.empty() ? "" : join(" else {\n", right.generateCode(), "\n}")
                );
            }

            @Override
            public MethodLevelSyntaxElement replace(final MethodLevelSyntaxElement search,
                final MethodLevelSyntaxElement replacement) {
                return ifCondition(
                    condition.replace(search, replacement),
                    (Closure) left.replace(search, replacement),
                    (Closure) right.replace(search, replacement)
                );
            }

            @Override
            public int count(final MethodLevelSyntaxElement search) {
                return condition.count(search) + left.count(search) + right.count(search);
            }
        };
    }

    /**
     * Syntax Element that cannot be replaced via
     * {@link MethodLevelSyntaxElement#replace(MethodLevelSyntaxElement, MethodLevelSyntaxElement)}.
     */
    public static final class IdentifierStatement implements ValueSyntaxElement {

        private final String value;

        private IdentifierStatement(final String value) {
            this.value = value;
        }

        @Override
        public String generateCode() {
            return value;
        }

        @Override
        public MethodLevelSyntaxElement replace(final MethodLevelSyntaxElement search,
            final MethodLevelSyntaxElement replacement) {
            return this;
        }

        @Override
        public int count(final MethodLevelSyntaxElement search) {
            return this == search ? 1 : 0;
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

        @Override
        public MethodLevelSyntaxElement replace(final MethodLevelSyntaxElement search,
            final MethodLevelSyntaxElement replacement) {
            return new SyntaxFactory.Assignment(field, value.replace(search, replacement));
        }

        @Override
        public int count(final MethodLevelSyntaxElement search) {
            return value.count(search);
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
        public MethodLevelSyntaxElement replace(final MethodLevelSyntaxElement search,
            final MethodLevelSyntaxElement replacement) {
            return this.equals(search) ? replacement : this;
        }

        @Override
        public int count(final MethodLevelSyntaxElement search) {
            return this.equals(search) ? 1 : 0;
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
        public MethodLevelSyntaxElement replace(final MethodLevelSyntaxElement search,
            final MethodLevelSyntaxElement replacement) {
            return this.equals(search) ? replacement : new SyntaxFactory.MethodCallReturnValue(
                instance.replace(search, replacement), method,
                args.stream().map(var -> var.replace(search, replacement))
                    .toArray(ValueSyntaxElement[]::new)
            );
        }

        @Override
        public int count(final MethodLevelSyntaxElement search) {
            return this.equals(search) ? 1 :
                instance.count(search) + args.stream().mapToInt(v -> v.count(search)).sum();
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
    }

    private static final class TypeCastStatement implements ValueSyntaxElement {

        private final Class<?> clazz;

        private final ValueSyntaxElement argument;

        private TypeCastStatement(final Class<?> clazz, final ValueSyntaxElement argument) {
            this.clazz = clazz;
            this.argument = argument;
        }

        @Override
        public MethodLevelSyntaxElement replace(final MethodLevelSyntaxElement search,
            final MethodLevelSyntaxElement replacement) {
            return new SyntaxFactory.TypeCastStatement(
                clazz, (ValueSyntaxElement) argument.replace(search, replacement)
            );
        }

        @Override
        public int count(final MethodLevelSyntaxElement search) {
            return argument.count(search);
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

        @Override
        public MethodLevelSyntaxElement replace(final MethodLevelSyntaxElement search,
            final MethodLevelSyntaxElement replacement) {
            return new SyntaxFactory.ReturnStatement(value.replace(search, replacement));
        }

        @Override
        public int count(final MethodLevelSyntaxElement search) {
            return value.count(search);
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

        @Override
        public MethodLevelSyntaxElement replace(final MethodLevelSyntaxElement search,
            final MethodLevelSyntaxElement replacement) {
            return new SyntaxFactory.TernaryStatement(
                (ValueSyntaxElement) condition.replace(search, replacement),
                (ValueSyntaxElement) left.replace(search, replacement),
                (ValueSyntaxElement) right.replace(search, replacement)
            );
        }

        @Override
        public int count(final MethodLevelSyntaxElement search) {
            return left.count(search) + right.count(search);
        }
    }
}
