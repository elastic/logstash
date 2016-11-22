package org.logstash.config.ir.expression;

import org.joni.Option;
import org.joni.Regex;
import org.logstash.config.ir.SourceComponent;
import org.logstash.config.ir.InvalidIRException;
import org.logstash.config.ir.SourceMetadata;

/**
 * Created by andrewvc on 9/15/16.
 */
public class RegexValueExpression extends ValueExpression {
    private final Regex regex;

    public RegexValueExpression(SourceMetadata meta, Object value) throws InvalidIRException {
        super(meta, value);

        if (!(value instanceof String)) {
            throw new InvalidIRException("Regex value expressions can only take strings!");
        }

        byte[] patternBytes = getSource().getBytes();
        this.regex = new Regex(patternBytes, 0, patternBytes.length, Option.NONE);
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
