package org.logstash.config.ir.expression;

import org.logstash.config.ir.InvalidIRException;
import org.logstash.common.SourceWithMetadata;

/**
 * Created by andrewvc on 9/13/16.
 */
public abstract class UnaryBooleanExpression extends BooleanExpression {
    private final Expression expression;

    public Expression getExpression() {
        return expression;
    }

    public UnaryBooleanExpression(SourceWithMetadata meta,
                                   Expression expression) throws InvalidIRException {
        super(meta);
        if (expression == null) throw new InvalidIRException("Unary expressions cannot operate on null!");
        this.expression = expression;
    }

    @Override
    public String hashSource() {
        return this.getClass().getCanonicalName() + "[" + this.expression.hashSource() + "]";
    }
}
