package org.logstash.common.parser;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.function.BiConsumer;
import java.util.function.Function;
import java.util.function.Supplier;
import java.util.stream.Collectors;

/**
 * A functional class which constructs an object from a given configuration map.
 * <p>
 * History: This is idea is taken largely from Elasticsearch's ConstructingObjectParser
 *
 * @param <Value> The object type to construct when `parse` is called.
 */
public class ConstructingObjectParser<Value> implements ObjectParser<Value> {
    private final Logger logger = LogManager.getLogger();
    private final Function<Object[], Value> builder;
    private final Map<String, FieldDefinition<Value>> parsers = new HashMap<>();
    private final Map<String, FieldDefinition<Object[]>> constructorArgs;

    /**
     * @param supplier The supplier which produces an object instance.
     */
    @SuppressWarnings("WeakerAccess") // Public Interface
    public ConstructingObjectParser(Supplier<Value> supplier) {
        this.builder = args -> supplier.get();

        // Reject any attempts to add constructor fields with an immutable map.
        constructorArgs = Collections.emptyMap();
    }

    /**
     * @param builder A function which takes an Object[] as argument and returns a Value instance
     */
    @SuppressWarnings("WeakerAccess") // Public Interface
    public ConstructingObjectParser(Function<Object[], Value> builder) {
        this.builder = builder;
        constructorArgs = new HashMap<>();
    }

    @Override
    @SuppressWarnings("WeakerAccess") // Public Interface
    public <T> Field declareField(String name, BiConsumer<Value, T> consumer, Function<Object, T> transform) {
        if (isKnownField(name)) {
            throw new IllegalArgumentException("Duplicate field defined '" + name + "'");
        }

        BiConsumer<Value, Object> objConsumer = (value, object) -> consumer.accept(value, transform.apply(object));
        FieldDefinition<Value> field = new FieldDefinition<>(objConsumer, FieldUsage.Field);
        parsers.put(name, field);
        return field;
    }

    @Override
    @SuppressWarnings("WeakerAccess") // Public Interface
    public <T> Field declareConstructorArg(String name, Function<Object, T> transform) {
        if (isKnownField(name)) {
            throw new IllegalArgumentException("Duplicate field defined '" + name + "'");
        }

        final int position = constructorArgs.size();
        BiConsumer<Object[], Object> objConsumer = (array, object) -> array[position] = transform.apply(object);
        FieldDefinition<Object[]> field = new FieldDefinition<>(objConsumer, FieldUsage.Constructor);
        try {
            constructorArgs.put(name, field);
        } catch (UnsupportedOperationException e) {
            // This will be thrown when this ConstructingObjectParser is created with a Supplier (which takes no arguments)
            // for example, new ConstructingObjectParser<>((Supplier<String>) String::new)
            throw new UnsupportedOperationException("Cannot add constructor args because the constructor doesn't take any arguments!");
        }
        return field;
    }

    /**
     * Construct an object using the given config.
     * <p>
     * The intent is that a config map, such as one from a Logstash pipeline config:
     * <p>
     * input {
     * example {
     * some => "setting"
     * goes => "here"
     * }
     * }
     * <p>
     * ... will know how to build an object for the above "example" input plugin.
     */
    public Value apply(Map<String, Object> config) {
        rejectUnknownFields(config.keySet());

        Value value = construct(config);

        // Now call all the object setters/etc
        for (Map.Entry<String, Object> entry : config.entrySet()) {
            String name = entry.getKey();
            if (constructorArgs.containsKey(name)) {
                // Skip constructor arguments
                continue;
            }

            FieldDefinition<Value> field = parsers.get(name);
            assert field != null;

            try {
                field.accept(value, entry.getValue());
            } catch (IllegalArgumentException e) {
                throw new IllegalArgumentException("Field " + name + ": " + e.getMessage(), e);
            }
        }

        return value;
    }

    private void rejectUnknownFields(Set<String> configNames) throws IllegalArgumentException {
        // Check for any unknown parameters.
        List<String> unknown = configNames.stream().filter(name -> !isKnownField(name)).collect(Collectors.toList());

        if (!unknown.isEmpty()) {
            throw new IllegalArgumentException("Unknown settings: " + unknown);
        }
    }

    private boolean isKnownField(String name) {
        return (parsers.containsKey(name) || constructorArgs.containsKey(name));
    }

    private Value construct(Map<String, Object> config) throws IllegalArgumentException {
        Object[] args = new Object[constructorArgs.size()];

        // Constructor arguments. Any constructor argument is a *required* setting.
        for (Map.Entry<String, FieldDefinition<Object[]>> argInfo : constructorArgs.entrySet()) {
            String name = argInfo.getKey();
            FieldDefinition<Object[]> field = argInfo.getValue();

            if (config.containsKey(name)) {
                if (field.isObsolete()) {
                    throw new IllegalArgumentException("Field '" + name + "' is obsolete and may not be used. " + field.getDetails());
                } else if (field.isDeprecated()) {
                    logger.warn("Field '" + name + "' is deprecated and should be avoided. " + field.getDetails());
                }

                field.accept(args, config.get(name));
            } else {
                throw new IllegalArgumentException("Missing required argument '" + name);
            }
        }

        return builder.apply(args);
    }
}
