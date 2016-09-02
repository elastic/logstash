package org.logstash.config.compiler;

import org.logstash.config.compiler.compiled.ICompiledExpression;
import org.logstash.config.ir.expression.Expression;

/**
 * Created by andrewvc on 9/22/16.
 */
public interface IExpressionCompiler {
    ICompiledExpression compile(Expression expression) throws CompilationError;
}
