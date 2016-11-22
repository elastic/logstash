package org.logstash.config.ir.expression;

import org.logstash.config.ir.SourceComponent;
import org.logstash.config.ir.InvalidIRException;
import org.logstash.config.ir.SourceMetadata;

/**
 * Created by andrewvc on 9/6/16.
 */
public abstract class BinaryBooleanExpression extends BooleanExpression {
    @Override
    public boolean sourceComponentEquals(SourceComponent sourceComponent) {
        if (sourceComponent == null) return false;
        if (this == sourceComponent) return true;
        if (this.getClass().equals(sourceComponent.getClass())) {
            BinaryBooleanExpression other = (BinaryBooleanExpression) sourceComponent;
            return (this.getLeft().sourceComponentEquals(other.getLeft()) &&
                    this.getRight().sourceComponentEquals(other.getRight()));
        }
        return false;
    }

    private final Expression left;
    private final Expression right;

    public Expression getRight() {
        return right;
    }

    public Expression getLeft() {
        return left;
    }

    public BinaryBooleanExpression(SourceMetadata meta,
                                   Expression left,
                                   Expression right) throws InvalidIRException {
        super(meta);
        this.left = left;
        this.right = right;
    }

    public abstract String rubyOperator();

    @Override
    public String toRubyString() {
        return "(" + getLeft().toRubyString() + rubyOperator() + getRight().toRubyString() + ")";
    }

    @Override
    public String hashSource() {
        return this.getClass().getCanonicalName() + "[" + getLeft().hashSource() + "|" + getRight().hashSource() + "]";
    }
}
