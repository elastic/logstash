package org.logstash.config.ir.expression;

import org.logstash.common.SourceWithMetadata;

public abstract class BooleanExpression extends Expression {
    public BooleanExpression(SourceWithMetadata meta) {
        super(meta);
    }
}
