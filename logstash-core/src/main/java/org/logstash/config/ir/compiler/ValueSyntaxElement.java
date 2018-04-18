package org.logstash.config.ir.compiler;

/**
 * An instance that can methods can be invoked on.
 */
interface ValueSyntaxElement extends MethodLevelSyntaxElement {

    /**
     * Call method on instance.
     * @param method Method Name
     * @param args Arguments to pass to Method
     * @return Method Return
     */
    default ValueSyntaxElement call(final String method, final MethodLevelSyntaxElement... args) {
        return new SyntaxFactory.MethodCallReturnValue(this, method, args);
    }
}
