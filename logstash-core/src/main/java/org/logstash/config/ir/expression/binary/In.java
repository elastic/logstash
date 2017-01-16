package org.logstash.config.ir.expression.binary;

import org.logstash.config.ir.InvalidIRException;
import org.logstash.config.ir.SourceMetadata;
import org.logstash.config.ir.expression.BinaryBooleanExpression;
import org.logstash.config.ir.expression.Expression;

/**
 * Created by andrewvc on 9/21/16.
 */
public class In extends BinaryBooleanExpression {
    public In(SourceMetadata meta, Expression left, Expression right) throws InvalidIRException {
        super(meta, left, right);
    }

    @Override
    public String rubyOperator() {
        return ".include?";
    }
}
