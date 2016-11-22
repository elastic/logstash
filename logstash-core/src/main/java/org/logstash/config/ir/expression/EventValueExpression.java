package org.logstash.config.ir.expression;

import org.logstash.config.ir.ISourceComponent;
import org.logstash.config.ir.SourceMetadata;

/**
 * Created by andrewvc on 9/13/16.
 */
public class EventValueExpression extends Expression {
    private final String fieldName;

    public EventValueExpression(SourceMetadata meta, String fieldName) {
        super(meta);
        this.fieldName = fieldName;
    }

    public String getFieldName() {
        return fieldName;
    }

    @Override
    public boolean sourceComponentEquals(ISourceComponent sourceComponent) {
        if (sourceComponent == null) return false;
        if (this == sourceComponent) return true;
        if (sourceComponent instanceof EventValueExpression) {
            EventValueExpression other = (EventValueExpression) sourceComponent;
            return (this.getFieldName().equals(other.getFieldName()));
        }
        return false;
    }

    @Override
    public String toString() {
        return "event.get('" + fieldName + "')";
    }

    @Override
    public String toRubyString() {
        return "event.getField('" + fieldName + "')";
    }
}
