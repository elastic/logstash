package org.logstash.config.ir.expression;

import org.logstash.common.SourceWithMetadata;
import org.logstash.config.ir.InvalidIRException;
import org.logstash.config.ir.SourceComponent;

public class RegexValueExpression extends ValueExpression {
    private final String regex;

    public RegexValueExpression(SourceWithMetadata meta, Object value) throws InvalidIRException {
        super(meta, value);

        if (!(value instanceof String)) {
            throw new InvalidIRException("Regex value expressions can only take strings!");
        }

        this.regex = getSource();
    }

    @Override
    public Object get() {
        return this.regex;
    }

    public String getSource() {
        return (String) value;
    }

    @Override
    public String toString() {
        return this.value.toString();
    }

    @Override
    public boolean sourceComponentEquals(SourceComponent other) {
        if (other == null) return false;
        if (other instanceof RegexValueExpression) {
            return (((RegexValueExpression) other).getSource().equals(getSource()));
        }
        return false;
    }

    @Override
    public String toRubyString() {
       return (String) value;
    }
}
