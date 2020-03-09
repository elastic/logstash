package org.logstash.config.ir.expression.unary;

import org.logstash.config.ir.SourceComponent;
import org.logstash.config.ir.InvalidIRException;
import org.logstash.common.SourceWithMetadata;
import org.logstash.config.ir.expression.Expression;
import org.logstash.config.ir.expression.UnaryBooleanExpression;

public class Not extends UnaryBooleanExpression {
    public Not(SourceWithMetadata meta, Expression expression) throws InvalidIRException {
        super(meta, expression);
    }

    @Override
    public String toRubyString() {
        return "!(" + getExpression().toRubyString() + ")";
    }

    @Override
    public boolean sourceComponentEquals(SourceComponent sourceComponent) {
        return sourceComponent != null &&
                (sourceComponent instanceof Not &&
                        ((Not) sourceComponent).getExpression().sourceComponentEquals(getExpression()));
    }
}
