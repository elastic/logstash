package org.logstash.config.ir.expression.binary;

import org.logstash.common.SourceWithMetadata;
import org.logstash.config.ir.expression.BinaryBooleanExpression;
import org.logstash.config.ir.expression.Expression;

/**
 * Created by andrewvc on 9/21/16.
 */
public class Neq extends BinaryBooleanExpression {
    public Neq(SourceWithMetadata meta, Expression left, Expression right) {
        super(meta, left, right);
    }

    @Override
    public String rubyOperator() {
        return "!=";
    }
}
