package org.logstash.config.ir.graph;

import org.logstash.config.ir.expression.BooleanExpression;

/**
 * Created by andrewvc on 9/15/16.
 */
public class IfVertex extends Vertex {
    private final BooleanExpression booleanExpression;

    public IfVertex(BooleanExpression booleanExpression) {
        this.booleanExpression = booleanExpression;
    }

    public String toString() {
        return "[if " + booleanExpression.toString(0) + "]";
    }
}
