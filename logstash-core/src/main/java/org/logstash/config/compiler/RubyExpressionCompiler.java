package org.logstash.config.compiler;

import org.jruby.RubyInstanceConfig;
import org.jruby.embed.ScriptingContainer;
import org.logstash.Event;
import org.logstash.config.compiler.compiled.ICompiledExpression;
import org.logstash.config.ir.expression.Expression;

import java.util.Collection;
import java.util.Collections;
import java.util.List;

/**
 * Created by andrewvc on 10/11/16.
 */
public class RubyExpressionCompiler implements IExpressionCompiler {
    private final ScriptingContainer container;
    private long expressionCounter;

    private class CompiledRubyExpression implements ICompiledExpression {
        private final String expressionSource;
        private final long expressionId;
        private final String methodName;

        public CompiledRubyExpression(long expressionId, String expressionSource) {
            this.expressionId = expressionId;
            this.methodName = "condition_" + expressionId;
            container.runScriptlet("def " + methodName + "(events); events.map {|event| " + expressionSource + " }; end");
            this.expressionSource = expressionSource;
        }

        @Override
        public List<Boolean> execute(Collection<Event> events) {
            // Unchecked cast because we enforce this ourselves. No need to take a speed hit here
            List<Boolean> result = (List<Boolean>) container.callMethod(null, methodName, events);
            return result;
        }
    }

    public RubyExpressionCompiler() {
        this.expressionCounter = 0l;
        this.container = new ScriptingContainer();
        this.container.setCompileMode(RubyInstanceConfig.CompileMode.FORCE);
    }

    @Override
    public ICompiledExpression compile(Expression expression) throws CompilationError {
        long expressionId = expressionCounter += 1;
        return new CompiledRubyExpression(expressionId, expression.toRubyString());
    }
}
