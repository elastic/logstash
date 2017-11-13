package org.logstash.config.ir.compiler;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;
import org.jruby.Ruby;
import org.jruby.runtime.ThreadContext;

/**
 * A syntactic closure.
 */
final class Closure implements MethodLevelSyntaxElement {

    /**
     * Empty and immutable {@link Closure}.
     */
    public static final Closure EMPTY = new Closure(Collections.emptyList());

    /**
     * Variable declaration for the Ruby thread-context,
     * renders as {@code final ThreadContext context}.
     */
    private static final VariableDefinition RUBY_THREAD_CONTEXT =
        new VariableDefinition(ThreadContext.class, "context");

    /**
     * Variable declaration for the Ruby thread-context,
     * renders as {@code final ThreadContext context = RubyUtil.RUBY.getCurrentContext()}.
     */
    private static final MethodLevelSyntaxElement CACHE_RUBY_THREADCONTEXT =
        SyntaxFactory.definition(
            RUBY_THREAD_CONTEXT, ValueSyntaxElement.GET_RUBY_THREAD_CONTEXT
        );

    /**
     * Variable referencing the current Ruby thread context.
     */
    private static final ValueSyntaxElement CACHED_RUBY_THREADCONTEXT =
        RUBY_THREAD_CONTEXT.access();

    private final List<MethodLevelSyntaxElement> statements;

    public static Closure wrap(final MethodLevelSyntaxElement... statements) {
        final Closure closure = new Closure();
        for (final MethodLevelSyntaxElement statement : statements) {
            if (statement instanceof Closure) {
                closure.add((Closure) statement);
            } else {
                closure.add(statement);
            }
        }
        return closure;
    }

    Closure() {
        this(new ArrayList<>());
    }

    private Closure(final List<MethodLevelSyntaxElement> statements) {
        this.statements = statements;
    }

    public Closure add(final Closure statement) {
        statements.addAll(statement.statements);
        return this;
    }

    public Closure add(final MethodLevelSyntaxElement statement) {
        statements.add(statement);
        return this;
    }

    @Override
    public String generateCode() {
        final Collection<MethodLevelSyntaxElement> optimized =
            this.optimizeRubyThreadContexts().statements;
        return optimized.isEmpty() ? "" : SyntaxFactory.join(
            optimized.stream().map(MethodLevelSyntaxElement::generateCode).collect(
                Collectors.joining(";\n")
            ), ";"
        );
    }

    /**
     * Removes duplicate calls to {@link Ruby#getCurrentContext()} by caching them to a variable.
     * @return Copy of this Closure without redundant calls to {@link Ruby#getCurrentContext()}
     */
    private Closure optimizeRubyThreadContexts() {
        final ArrayList<Integer> rubyCalls = new ArrayList<>();
        for (int i = 0; i < statements.size(); ++i) {
            if (statements.get(i).count(ValueSyntaxElement.GET_RUBY_THREAD_CONTEXT) > 0) {
                rubyCalls.add(i);
            }
        }
        final Closure optimized;
        if (rubyCalls.size() > 1) {
            optimized = (Closure) new Closure().add(this).replace(
                ValueSyntaxElement.GET_RUBY_THREAD_CONTEXT, CACHED_RUBY_THREADCONTEXT
            );
            optimized.statements.add(rubyCalls.get(0), CACHE_RUBY_THREADCONTEXT);
        } else {
            optimized = this;
        }
        return optimized;
    }

    @Override
    public MethodLevelSyntaxElement replace(final MethodLevelSyntaxElement search,
        final MethodLevelSyntaxElement replacement) {
        final Closure result = new Closure();
        for (final MethodLevelSyntaxElement element : this.statements) {
            result.add(element.replace(search, replacement));
        }
        return result;
    }

    @Override
    public int count(final MethodLevelSyntaxElement search) {
        return statements.stream().mapToInt(child -> child.count(search)).sum();
    }
}
