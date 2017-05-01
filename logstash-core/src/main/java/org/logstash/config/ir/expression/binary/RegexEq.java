package org.logstash.config.ir.expression.binary;

import org.logstash.config.ir.InvalidIRException;
import org.logstash.common.SourceWithMetadata;
import org.logstash.config.ir.expression.BinaryBooleanExpression;
import org.logstash.config.ir.expression.Expression;
import org.logstash.config.ir.expression.RegexValueExpression;

/**
 * Created by andrewvc on 9/21/16.
 */
public class RegexEq extends BinaryBooleanExpression {
    public RegexEq(SourceWithMetadata meta, Expression left, Expression right) throws InvalidIRException {
        super(meta, left, right);

        if (!(right instanceof RegexValueExpression)) {
            throw new InvalidIRException("You must use a regexp operator with a regexp rval!" + right);
        }
    }

    @Override
    public String rubyOperator() {
        return "=~";
    }
}
