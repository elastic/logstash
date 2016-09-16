package org.logstash.config.ir.expression;

import org.logstash.config.ir.InvalidIRException;
import org.logstash.config.ir.SourceComponent;
import org.logstash.config.ir.SourceMetadata;

/**
 * Created by andrewvc on 9/6/16.
 */
public class BinaryBooleanExpression extends BooleanExpression {
    @Override
    public boolean sourceComponentEquals(SourceComponent sourceComponent) {
        if (sourceComponent == null) return false;
        if (this == sourceComponent) return true;
        if (sourceComponent instanceof BinaryBooleanExpression) {
            BinaryBooleanExpression other = (BinaryBooleanExpression) sourceComponent;
            return (this.getOperator() == other.getOperator() &&
                    this.getLeft().sourceComponentEquals(other.getLeft()) &&
                    this.getRight().sourceComponentEquals(other.getRight()));
        }
        return false;
    }

    public enum Operator {
        GT,
        LT,
        GTE,
        LTE,
        EQ,
        NEQ,
        IN,
        REGEXPEQ,
        REGEXPNEQ,
        AND,
        OR
    }

    private final Operator operator;
    private final Expression left;
    private final Expression right;

    public Expression getRight() {
        return right;
    }

    public Expression getLeft() {
        return left;
    }

    public Operator getOperator() {
        return operator;
    }

    public BinaryBooleanExpression(SourceMetadata meta,
                                   Operator operator,
                                   Expression left,
                                   Expression right) throws InvalidIRException {
        super(meta);

        boolean isRegexpOp = ((operator == Operator.REGEXPEQ || operator == Operator.REGEXPNEQ));
        boolean isRegexRval = (right instanceof RegexValueExpression);
        if (isRegexpOp ^ isRegexRval) {
            throw new InvalidIRException("You must use a regexp operator with a regexp rval! Op: " + operator + " rval " + right);
        }

        this.operator = operator;
        this.left = left;
        this.right = right;
    }

    @Override
    public String toString(int indent) {
        return indentPadding(indent) + "(" + operator.toString().toLowerCase() + " " + left.toString(0) + " " + right.toString(0) + ")";
    }
}
