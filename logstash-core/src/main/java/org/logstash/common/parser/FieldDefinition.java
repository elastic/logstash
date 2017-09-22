package org.logstash.common.parser;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.util.function.Function;

class FieldDefinition<Value> implements Field<Value> {
    private static final Logger logger = LogManager.getLogger();
    private final Function<Object, Value> transform;

    private final String name;

    // This is only set if deprecated or obsolete
    // XXX: Move this concept separately to DeprecatedFieldDefinition and ObsoleteFieldDefinition
    private FieldStatus status = FieldStatus.Supported;
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
        if (object == null) {
            throw new NullPointerException("The '" + name + "' field is required and no value was provided.");
        }
        switch (status) {
            // XXX: use Structured logging + localization lookups.
            case Deprecated:
                logger.warn("The field '" + getName() + "' is deprecated and will be removed soon: " + getDetails());
                break;
            case Obsolete:
                logger.fatal("The field '" + getName() + "' is obsolete and has been removed: " + getDetails());
                break;
            case Supported:
                break;
        }

        return transform.apply(object);
    }

    public String getName() {
        return name;
    }

    @Override
    public String getDetails() {
        return details;
    }
}
