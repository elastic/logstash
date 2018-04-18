package org.logstash.config.ir.compiler;

/**
 * A {@link SyntaxElement} that is part of a method body.
 */
interface MethodLevelSyntaxElement extends SyntaxElement {

    /**
     * Syntax element that generates {@code return null}.
     */
    MethodLevelSyntaxElement RETURN_NULL = SyntaxFactory.ret(SyntaxFactory.value("null"));
}
