package org.logstash.common.parser;

import java.util.function.Function;

class FieldDefinition<Value> implements Field<Value> {
    private final Function<Object, Value> transform;

    private String name;

    // This is only set if deprecated or obsolete
    // XXX: Move this concept separately to DeprecatedFieldDefinition and ObsoleteFieldDefinition
    private FieldStatus status;
    private String details;

    FieldDefinition(String name, Function<Object, Value> transform) {
        this.name = name;
        this.transform = transform;
    }

    @Override
    public Field setDeprecated(String details) {
        setStatus(FieldStatus.Deprecated, details);
        return this;
    }

    @Override
    public Field setObsolete(String details) {
        setStatus(FieldStatus.Obsolete, details);
        return this;
    }

    private void setStatus(FieldStatus status, String details) {
        this.status = status;
        this.details = details;
    }

    @Override
    public Value apply(Object object) {
        return transform.apply(object);
    }

    @Override
    public boolean isDeprecated() {
        return status == FieldStatus.Deprecated;
    }

    @Override
    public boolean isObsolete() {
        return status == FieldStatus.Obsolete;
    }

    public String getName() {
        return name;
    }

    @Override
    public String getDetails() {
        return details;
    }
}
