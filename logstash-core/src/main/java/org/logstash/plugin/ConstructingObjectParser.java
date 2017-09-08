package org.logstash.plugin;

import java.util.*;
import java.util.function.BiConsumer;
import java.util.function.Supplier;

/**
 * This is idea is taken largely from Elasticsearch but is unavailable as a library, so the code exists here as well.
 *
 * @param <T> The object type to construct.
 */
public class ConstructingObjectParser<Value> {
    private final String name;
    //private final Function<Object[], Value> builder;
    private final Supplier<Value> builder;
    private final Map<String, BiConsumer<Value, Object>> parsers = new HashMap<>();
    private final List<BiConsumer<Value, ?>> constructorArgs = new ArrayList<>();

    //public ConstructingObjectParser(String name, Function<Object[], Value> builder) {
    public ConstructingObjectParser(String name, Supplier<Value> builder) {
        this.name = name;
        this.builder = builder;
    }

    static <Value> BiConsumer<Value, Object> integerTransform(BiConsumer<Value, Integer> consumer) {
        return (value, object) -> {
            if (object instanceof Integer) {
                consumer.accept(value, (Integer) object);
            } else if (object instanceof String) {
                consumer.accept(value, Integer.parseInt((String) object));
            }
        };
    }

    static <Value> BiConsumer<Value, Object> stringTransform(BiConsumer<Value, String> consumer) {
        return (value, object) -> {
            if (object instanceof String) {
                consumer.accept(value, (String) object);
            } else if (object instanceof Number) {
                consumer.accept(value, object.toString());
            } else {
                throw new IllegalArgumentException("Value must be a string, but is a " + object.getClass());
            }
        };
    }

    public void declareField(String name, BiConsumer<Value, Object> consumer) {
        parsers.put(name, consumer);
    }

    public void declareInteger(String name, BiConsumer<Value, Integer> consumer) {
        declareField(name, integerTransform(consumer));
    }

    public Value parse(Map<String, Object> config) {
        Value value = this.builder.get();

        Set<String> missing = new TreeSet<>();
        missing.addAll(parsers.keySet());
        missing.retainAll(config.keySet());

        Set<String> unknown = new TreeSet<>();
        unknown.addAll(config.keySet());
        unknown.retainAll(parsers.keySet());

        for (Map.Entry<String, Object> entry : config.entrySet()) {
            String name = entry.getKey();
            BiConsumer<Value, Object> parser = parsers.get(entry.getKey());
            parser.accept(value, entry.getValue());
        }

        return value;
    }
}
