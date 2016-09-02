package org.logstash.config.ir.compiler;

import org.junit.Test;
import org.logstash.Event;
import org.logstash.config.compiler.CompilationError;
import org.logstash.config.compiler.compiled.ICompiledExpression;
import org.logstash.config.compiler.RubyExpressionCompiler;
import org.logstash.config.ir.InvalidIRException;
import org.logstash.config.ir.expression.Expression;

import static junit.framework.TestCase.assertFalse;
import static org.junit.Assert.assertTrue;
import static org.logstash.config.ir.DSL.*;


/**
 * Created by andrewvc on 10/11/16.
 */
public class ExpressionCompilerTest {
    @Test
    public void testSimpleEquality() throws InvalidIRException, CompilationError {
        assertExpressionTrue(eEq(eValue(1), eValue(1)));
        assertExpressionFalse(eEq(eValue(1), eValue(2)));
    }

    @Test
    public void testFieldComparison() throws InvalidIRException, CompilationError {
        Event event = new Event();
        event.setField("[foo]", "bar");

        assertExpressionTrue(eEq(eEventValue("foo"), eValue("bar")), event);
        assertExpressionFalse(eEq(eEventValue("foo"), eValue("WRONG!")), event);
    }

    @Test
    public void testNested() throws InvalidIRException, CompilationError {
        assertExpressionTrue(eAnd(
                eGt(eValue(2), eValue(1)),
                eLt(eValue(100), eValue(1000))));

        assertExpressionFalse(eOr(
                eGt(eValue(-1), eValue(1)),
                eLt(eValue(100000), eValue(1000))));
    }

    public void assertExpressionTrue(Expression expression) throws CompilationError {
        assertExpressionTrue(expression, new Event());
    }

    public void assertExpressionTrue(Expression expression, Event event) throws CompilationError {
        assertTrue("Expected expr to be true: " + expression.toRubyString() + " Event: " + event.getData(), runExpression(expression, event));
    }

    public void assertExpressionFalse(Expression expression) throws CompilationError {
        assertExpressionFalse(expression, new Event());
    }

    public void assertExpressionFalse(Expression expression, Event event) throws CompilationError {
       assertFalse("Expected expr to be false: " + expression.toRubyString() + " Event: " + event.getData(), runExpression(expression, event));
    }

    public boolean runExpression(Expression expression, Event event) throws CompilationError {
        RubyExpressionCompiler expressionCompiler = new RubyExpressionCompiler();
        ICompiledExpression compiled = expressionCompiler.compile(expression);
        return compiled.execute(event);
    }
}
