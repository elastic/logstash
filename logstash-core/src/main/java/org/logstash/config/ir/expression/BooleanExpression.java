package org.logstash.config.ir.expression;

import org.logstash.common.SourceWithMetadata;

/**
 * Created by andrewvc on 9/14/16.
 */
public abstract class BooleanExpression extends Expression {
    public BooleanExpression(SourceWithMetadata meta) {
        super(meta);
    }
}
