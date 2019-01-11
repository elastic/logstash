package org.logstash.common.parser;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.util.function.Function;

public class DeprecatedField<Value> extends FieldDefinition<Value> {
    private static final Logger logger = LogManager.getLogger();
    private final String details;

    DeprecatedField(String name, Function<Object, Value> transform, String details) {
        super(name, transform);
        this.details = details;
    }

    @Override
    public Value apply(Object object) {
        if (object != null) {
            logger.warn("The field '" + getName() + "' is deprecated and will be removed soon: " + details);
        }
        return super.apply(object);
    }
}
