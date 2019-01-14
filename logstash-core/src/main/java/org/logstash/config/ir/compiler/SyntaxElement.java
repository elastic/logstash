package org.logstash.config.ir.compiler;

/**
 * Syntax element that can be rendered to Java sourcecode.
 */
interface SyntaxElement {

    /**
     * @return Java code that can be compiled by Janino
     */
    String generateCode();
}
