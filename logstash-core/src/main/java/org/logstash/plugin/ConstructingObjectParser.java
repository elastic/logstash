package org.logstash.plugin;

import java.util.*;
import java.util.function.BiConsumer;
import java.util.function.Function;
import java.util.function.Supplier;
import java.util.stream.Collectors;

/**
 * A functional class which constructs an object from a given configuration map.
 *
 * History: This is idea is taken largely from Elasticsearch's ConstructingObjectParser
 *
 * @param <Value> The object type to construct when `parse` is called.
 */
public class ConstructingObjectParser<Value> implements Function<Map<String, Object>, Value> {
    private final Function<Object[], Value> builder;
    private final Map<String, BiConsumer<Value, Object>> parsers = new LinkedHashMap<>();
    private final Map<String, BiConsumer<Object[], Object>> constructorArgs;

    @SuppressWarnings("WeakerAccess") // Public Interface
    public ConstructingObjectParser(Supplier<Value> supplier) {
        this.builder = args -> supplier.get();

        // Reject any attempts to add constructor fields with an immutable map.
        constructorArgs = Collections.emptyMap();
    }

    @SuppressWarnings("WeakerAccess") // Public Interface
    public ConstructingObjectParser(Function<Object[], Value> builder) {
        this.builder = builder;
        constructorArgs = new TreeMap<>();
    }

    @SuppressWarnings("WeakerAccess") // Public Interface
    public static Integer integerTransform(Object object) {
        if (object instanceof Number) {
            return ((Number) object).intValue();
        } else if (object instanceof String) {
            return Integer.parseInt((String) object);
        } else {
            throw new IllegalArgumentException("Value must be a number, but is a " + object.getClass());
        }
    }

    @SuppressWarnings("WeakerAccess") // Public Interface
    public static Float floatTransform(Object object) {
        if (object instanceof Number) {
            return ((Number) object).floatValue();
        } else if (object instanceof String) {
            return Float.parseFloat((String) object);
        } else {
            throw new IllegalArgumentException("Value must be a number, but is a " + object.getClass());
        }
    }

    @SuppressWarnings("WeakerAccess") // Public Interface
    public static Double doubleTransform(Object object) {
        if (object instanceof Number) {
            return ((Number) object).doubleValue();
        } else if (object instanceof String) {
            return Double.parseDouble((String) object);
        } else {
            throw new IllegalArgumentException("Value must be a number, but is a " + object.getClass());
        }
    }

    @SuppressWarnings("WeakerAccess") // Public Interface
    public static Long longTransform(Object object) {
        if (object instanceof Number) {
            return ((Number) object).longValue();
        } else if (object instanceof String) {
            return Long.parseLong((String) object);
        } else {
            throw new IllegalArgumentException("Value must be a number, but is a " + object.getClass());
        }
    }

    @SuppressWarnings("WeakerAccess") // Public Interface
    public static String stringTransform(Object object) {
        if (object instanceof String) {
            return (String) object;
        } else if (object instanceof Number) {
            return object.toString();
        } else {
            throw new IllegalArgumentException("Value must be a string, but is a " + object.getClass());
        }
    }

    @SuppressWarnings("WeakerAccess") // Public Interface
    public static Boolean booleanTransform(Object object) {
        if (object instanceof Boolean) {
            return (Boolean) object;
        } else if (object instanceof String) {
            switch ((String) object) {
                case "true":
                    return true;
                case "false":
                    return false;
                default:
                    throw new IllegalArgumentException("Value must be a boolean 'true' or 'false', but is " + object);
            }
        } else {
            throw new IllegalArgumentException("Value must be a boolean, but is " + object.getClass());
        }
    }

    @SuppressWarnings("WeakerAccess") // Public Interface
    public static <T> T objectTransform(Object object, ConstructingObjectParser<T> parser) {
        if (object instanceof Map) {
            // XXX: Fix this unchecked cast.
            return parser.apply((Map<String, Object>) object);
        } else {
            throw new IllegalArgumentException("Object value must be a Map, but is a " + object.getClass());
        }
    }

    /**
     * Add an field with an long value.
     *
     * @param name     the name of this field
     * @param consumer the function to call once the value is available
     */
    @SuppressWarnings("WeakerAccess") // Public Interface
    public void declareLong(String name, BiConsumer<Value, Long> consumer) {
        declareField(name, consumer, ConstructingObjectParser::longTransform);
    }

    /**
     * Declare an long constructor argument.
     *
     * @param name the name of the field.
     */
    @SuppressWarnings("WeakerAccess") // Public Interface
    public void declareLong(String name) {
        declareConstructorArg(name, ConstructingObjectParser::longTransform);
    }

    /**
     * Add an field with an integer value.
     *
     * @param name the name of this field
     * @param consumer the function to call once the value is available
     */
    @SuppressWarnings("WeakerAccess") // Public Interface
    public void declareInteger(String name, BiConsumer<Value, Integer> consumer) {
        declareField(name, consumer, ConstructingObjectParser::integerTransform);
    }

    /**
     * Declare an integer constructor argument.
     *
     * @param name the name of the field.
     */
    @SuppressWarnings("WeakerAccess") // Public Interface
    public void declareInteger(String name) {
        declareConstructorArg(name, ConstructingObjectParser::integerTransform);
    }

    /**
     * Add a field with a string value.
     *
     * @param name the name of this field
     * @param consumer the function to call once the value is available
     */
    @SuppressWarnings("WeakerAccess") // Public Interface
    public void declareString(String name, BiConsumer<Value, String> consumer) {
        declareField(name, consumer, ConstructingObjectParser::stringTransform);
    }

    /**
     * Declare a constructor argument that is a string.
     *
     * @param name the name of this field.
     */
    @SuppressWarnings("WeakerAccess") // Public Interface
    public void declareString(String name) {
        declareConstructorArg(name, ConstructingObjectParser::stringTransform);
    }

    @SuppressWarnings("WeakerAccess") // Public Interface
    public void declareFloat(String name) {
        declareConstructorArg(name, ConstructingObjectParser::floatTransform);
    }

    @SuppressWarnings("WeakerAccess") // Public Interface
    public <T> void declareField(String name, BiConsumer<Value, T> consumer, Function<Object, T> transform) {
        BiConsumer<Value, Object> objConsumer = (value, object) -> consumer.accept(value, transform.apply(object));
        parsers.put(name, objConsumer);
    }

    @SuppressWarnings("WeakerAccess") // Public Interface
    public <T> void declareConstructorArg(String name, Function<Object, T> transform) {
        final int position = constructorArgs.size();
        BiConsumer<Object[], Object> objConsumer = (array, object) -> array[position] = transform.apply(object);
        constructorArgs.put(name, objConsumer);
    }

    @SuppressWarnings("WeakerAccess") // Public Interface
    public void declareFloat(String name, BiConsumer<Value, Float> consumer) {
        declareField(name, consumer, ConstructingObjectParser::floatTransform);
    }

    @SuppressWarnings("WeakerAccess") // Public Interface
    public void declareDouble(String name) {
        declareConstructorArg(name, ConstructingObjectParser::doubleTransform);
    }

    @SuppressWarnings("WeakerAccess") // Public Interface
    public void declareDouble(String name, BiConsumer<Value, Double> consumer) {
        declareField(name, consumer, ConstructingObjectParser::doubleTransform);
    }

    private Value construct(Map<String, Object> config) {
        // XXX: Maybe this can just be an Object[]
        Object[] args = new Object[constructorArgs.size()];

        // Constructor arguments. Any constructor argument is a *required* setting.
        for (Map.Entry<String, BiConsumer<Object[], Object>> argInfo : constructorArgs.entrySet()) {
            String name = argInfo.getKey();
            BiConsumer<Object[], Object> argsBuilder = argInfo.getValue();
            if (config.containsKey(name)) {
                argsBuilder.accept(args, config.get(name));
            } else {
                throw new IllegalArgumentException("Missing required argument '" + name + "' for " + getClass());
            }
        }

        return builder.apply(args);
    }

    @SuppressWarnings("WeakerAccess") // Public Interface
    public void declareBoolean(String name) {
        declareConstructorArg(name, ConstructingObjectParser::booleanTransform);
    }

    @SuppressWarnings("WeakerAccess") // Public Interface
    public void declareBoolean(String name, BiConsumer<Value, Boolean> consumer) {
        declareField(name, consumer, ConstructingObjectParser::booleanTransform);
    }

    /**
     * Add a field with an object value
     *
     * @param name the name of this field
     * @param consumer the function to call once the value is available
     * @param parser The ConstructingObjectParser that will build the object
     * @param <T> The type of object to store as the value.
     */
    @SuppressWarnings("WeakerAccess") // Public Interface
    public <T> void declareObject(String name, BiConsumer<Value, T> consumer, ConstructingObjectParser<T> parser) {
        declareField(name, consumer, (t) -> objectTransform(t, parser));
    }

    /**
     * Declare a constructor argument that is an object.
     *
     * @param name   the name of the field which represents this constructor argument
     * @param parser the ConstructingObjectParser that builds the object
     * @param <T>    The type of object created by the parser.
     */
    @SuppressWarnings("WeakerAccess") // Public Interface
    public <T> void declareObject(String name, ConstructingObjectParser<T> parser) {
        declareConstructorArg(name, (t) -> objectTransform(t, parser));
    }

    /**
     * Construct an object using the given config.
     *
     * The intent is that a config map, such as one from a Logstash pipeline config:
     *
     *     input {
     *         example {
     *             some => "setting"
     *             goes => "here"
     *         }
     *     }
     *
     *  ... will know how to build an object for the above "example" input plugin.
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

            BiConsumer<Value, Object> parser = parsers.get(name);
            assert parser != null;

            try {
                parser.accept(value, entry.getValue());
            } catch (IllegalArgumentException e) {
                throw new IllegalArgumentException("Field " + name + ": " + e.getMessage(), e);
            }
        }

        return value;
    }

    private boolean isKnownField(String name) {
        return (parsers.containsKey(name) || constructorArgs.containsKey(name));
    }

    private void rejectUnknownFields(Set<String> configNames) {
        // Check for any unknown parameters.
        List<String> unknown = configNames.stream().filter(name -> !isKnownField(name)).collect(Collectors.toList());

        if (!unknown.isEmpty()) {
            throw new IllegalArgumentException("Unknown settings: " + unknown);
        }
    }
}
