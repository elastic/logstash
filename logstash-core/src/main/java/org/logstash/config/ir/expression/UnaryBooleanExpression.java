package org.logstash.config.ir.expression;

import org.logstash.config.ir.SourceComponent;
import org.logstash.config.ir.SourceMetadata;

/**
 * Created by andrewvc on 9/13/16.
 */
public class UnaryBooleanExpression extends BooleanExpression {
    @Override
    public boolean sourceComponentEquals(SourceComponent sourceComponent) {
        if (sourceComponent == null) return false;
        if (sourceComponent == this) return true;
        if (sourceComponent instanceof UnaryBooleanExpression) {
            UnaryBooleanExpression other = (UnaryBooleanExpression) sourceComponent;
            return (this.operator == other.getOperator() &&
                    ((this.getExpression() == null && other.getExpression() == null) ||
                            (this.getExpression().sourceComponentEquals(other.getExpression()))));
        }
        return false;
    }

    public enum Operator {
        NOT,
        NOTNULL,
        ISNULL
    }

    private final Operator operator;
    private final Expression expression;

    public Expression getExpression() {
        return expression;
    }

    public Operator getOperator() {
        return operator;
    }

    public UnaryBooleanExpression(SourceMetadata meta,
                                   Operator operator,
                                   Expression expression) {
        super(meta);
        this.operator = operator;
        this.expression = expression;
    }

    @Override
    public String toString(int indent) {
        String exStr = expression == null ? "null" : expression.toString(0);
        return indentPadding(indent) + "(" + operator.toString().toLowerCase() + " " + exStr + ")";
    }
}
