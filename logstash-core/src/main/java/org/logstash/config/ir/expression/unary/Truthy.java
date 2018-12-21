package org.logstash.config.ir.expression.unary;

import org.logstash.config.ir.SourceComponent;
import org.logstash.config.ir.InvalidIRException;
import org.logstash.common.SourceWithMetadata;
import org.logstash.config.ir.expression.Expression;
import org.logstash.config.ir.expression.UnaryBooleanExpression;

public class Truthy extends UnaryBooleanExpression {
    public Truthy(SourceWithMetadata meta, Expression expression) throws InvalidIRException {
        super(meta, expression);
    }

    @Override
    public String toRubyString() {
        return "(" + this.getExpression() + ")";
    }

    @Override
    public boolean sourceComponentEquals(SourceComponent sourceComponent) {
        return sourceComponent != null &&
                sourceComponent instanceof Truthy &&
                ((Truthy) sourceComponent).getExpression().sourceComponentEquals(this.getExpression());
    }
}
