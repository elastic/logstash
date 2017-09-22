package org.logstash.common.parser;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.util.function.Function;

public class ObsoleteField<Value> extends FieldDefinition<Value> {
    private static final Logger logger = LogManager.getLogger();
    private final String details;

    ObsoleteField(String name, Function<Object, Value> transform, String details) {
        super(name, transform);
        this.details = details;
    }

    @Override
    public Value apply(Object object) {
        String message = "The field '" + getName() + "' is obsolete and no longer functions. Remove it from your configuration. " + details;
        logger.fatal(message);
        throw new IllegalArgumentException(message);
    }
}
