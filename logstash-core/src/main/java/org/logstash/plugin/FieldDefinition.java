package org.logstash.plugin;

import java.util.function.BiConsumer;

class FieldDefinition<Value> implements Field, BiConsumer<Value, Object> {
    private final FieldUsage usage;
    private final BiConsumer<Value, Object> consumer;

    private String details;
    private FieldStatus status;

    FieldDefinition(BiConsumer<Value, Object> consumer, FieldUsage usage) {
        this.consumer = consumer;
        this.usage = usage;
    }

    @Override
    public Field setDeprecated(String details) {
        setStatus(FieldStatus.Deprecated, details);
        return this;
    }

    @Override
    public Field setObsolete(String details) {
        if (usage == FieldUsage.Constructor) {
            throw new IllegalArgumentException("Constructor arguments cannot be made obsolete.");
        }
        setStatus(FieldStatus.Obsolete, details);
        return this;
    }

    private void setStatus(FieldStatus status, String details) {
        this.status = status;
        this.details = details;
    }

    @Override
    public void accept(Value value, Object object) {
        consumer.accept(value, object);
    }

    boolean isDeprecated() {
        return status == FieldStatus.Deprecated;
    }

    boolean isObsolete() {
        return status == FieldStatus.Obsolete;
    }

    String getDetails() {
        return details;
    }
}
