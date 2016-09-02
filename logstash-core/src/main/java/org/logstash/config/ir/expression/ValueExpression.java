package org.logstash.config.ir.expression;

import org.joni.Regex;
import org.logstash.config.ir.InvalidIRException;
import org.logstash.config.ir.SourceComponent;
import org.logstash.config.ir.SourceMetadata;

import java.math.BigDecimal;
import java.util.List;

/**
 * Created by andrewvc on 9/13/16.
 */
public class ValueExpression extends Expression {
    protected final Object value;

    public ValueExpression(SourceMetadata meta, Object value) throws InvalidIRException {
        super(meta);

        if (!(value == null ||
                value instanceof Short ||
                value instanceof Long ||
                value instanceof Integer ||
                value instanceof Float ||
                value instanceof Double ||
                value instanceof BigDecimal ||
                value instanceof String ||
                value instanceof List ||
                value instanceof java.time.Instant
        )) {
            throw new InvalidIRException("Invalid eValue " + value + " with class " + value.getClass().getName());
        }

        this.value = value;
    }

    public Object get() {
        return value;
    }

    @Override
    public boolean sourceComponentEquals(SourceComponent sourceComponent) {
        if (sourceComponent == null) return false;
        if (this == sourceComponent) return true;
        if (sourceComponent instanceof ValueExpression) {
            ValueExpression other = (ValueExpression) sourceComponent;
            return (this.get().equals(other.get()));
        }
        return false;
    }

    @Override
    public String toString(int indent) {
        if (value == null) {
            return "null";
        }
        if (value instanceof String) {
            return "'" + get() + "'";
        }

        return indentPadding(indent) + get().toString();
    }
}
