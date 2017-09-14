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

    /**
     * Declare a field. Field ordering does not matter.
     * <p>
     * A field is intended to call a Setter on an Object.
     * <p>
     * When calling `apply`, all fields are considered optional and may be absent from the config map.
     * <p>
     * <code>{@code
     * ConstructingObjectParser<SocketServer> c = new ConstructingObjectParser<>(SocketServer::new)
     * c.declareBoolean("reuseAddress", SocketServer::setReuseAddress);
     * c.declareInteger("receiveBufferSize", SocketServer::setReceiveBufferSize);
     * <p>
     * Map<String, Object> config = new HashMap<>();
     * config.put("reuseAddress", true);
     * config.put("receiveBufferSize", 65536);
     * SocketServer server = c.apply(config);
     * }</code>
     *
     * @param name
     * @param consumer
     * @param transform
     * @param <T>
     * @return
     */
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

    /**
     * Declare a constructor argument. Constructor arguments are implicitly ordered by the order they are executed.
     * <p>
     * When calling `apply`, all constructor arguments are considered required. If missing, `apply` will throw an exception.
     * <p>
     * <code>{@code
     * ConstructingObjectParser<Integer> c = new ConstructingObjectParser<>(args -> new Integer((int) args[0])0;
     * c.declareInteger("number");
     * <p>
     * // alternately, the longer way:
     * //c.declareConstructorArg("number", ObjectTransform::transformInteger)
     * <p>
     * Integer i = c.apply(Collections.singletonMap("number", 100);
     * // i == 100
     * }</code>
     *
     * @param name      The name of this constructor argument
     * @param transform The function to transform an Object to the specified T type
     * @param <T>       the type of value expected for this constructor arg.
     * @return
     */
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
     * Use the given config to produce the Value object.
     *
     * Contract:
     * 1) All declared constructor arguments are required. If any are missing, an IllegalArgumentException is thrown.
     * 2) All declared fields are optional.
     * 3) Any unknown fields found will cause this method to throw an IllegalArgumentException.
     * 4) If any field processing fails, an IllegalArgumentException is thrown
     *
     * @param config the configuration
     * @return the configured object
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
