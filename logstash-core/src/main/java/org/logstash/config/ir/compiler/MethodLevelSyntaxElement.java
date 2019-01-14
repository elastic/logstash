package org.logstash.config.ir.compiler;

/**
 * A {@link SyntaxElement} that is part of a method body.
 */
interface MethodLevelSyntaxElement extends SyntaxElement {

    /**
     * Syntax element that generates {@code return null}.
     */
    MethodLevelSyntaxElement RETURN_NULL = SyntaxFactory.ret(SyntaxFactory.value("null"));

    /**
     * Replace any occurrences of {@code search} by {@code replacement} in this element.
     * @param search Syntax element to replace
     * @param replacement Replacement
     * @return A copy of this element with the replacement applied
     */
    MethodLevelSyntaxElement replace(MethodLevelSyntaxElement search,
        MethodLevelSyntaxElement replacement);

    /**
     * Count the number of occurrences of {@code search} in this element.
     * @param search Element to count
     * @return Number of occurrences
     */
    int count(MethodLevelSyntaxElement search);
}
