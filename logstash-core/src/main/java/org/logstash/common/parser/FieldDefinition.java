package org.logstash.common.parser;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.util.function.Function;

class FieldDefinition<Value> implements Field<Value> {
    private static final Logger logger = LogManager.getLogger();
    private final Function<Object, Value> transform;

    private final String name;

    // XXX: Should Field definitions be separated in Field, DeprecatedField, ObsoleteField ?
    private FieldStatus status = FieldStatus.Supported;
    private String details;

    FieldDefinition(String name, Function<Object, Value> transform) {
        this.name = name;
        this.transform = transform;
    }

    @Override
    public Value apply(Object object) {
        if (object == null) {
            throw new NullPointerException("The '" + name + "' field is required and no value was provided.");
        }
        return transform.apply(object);
    }

    @Override
    public String getName() {
        return name;
    }

    @Override
    public String getDetails() {
        return details;
    }
}
