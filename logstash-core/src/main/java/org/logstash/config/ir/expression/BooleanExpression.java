package org.logstash.config.ir.expression;

import org.logstash.config.ir.SourceMetadata;

/**
 * Created by andrewvc on 9/14/16.
 */
public abstract class BooleanExpression extends Expression {
    public BooleanExpression(SourceMetadata meta) {
        super(meta);
    }
}
