package org.logstash.plugin;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;
import java.util.function.BiConsumer;
import java.util.function.Supplier;

/**
 * This is idea is taken largely from Elasticsearch but is unavailable as a library, so the code exists here as well.
 *
 * @param <Value> The object type to construct when `parse` is called.
 */
public class ConstructingObjectParser<Value> {
    private final Supplier<Value> builder;
    private final Map<String, BiConsumer<Value, Object>> parsers = new LinkedHashMap<>();

    public ConstructingObjectParser(Supplier<Value> builder) {
        this.builder = builder;
    }

    private static <Value> BiConsumer<Value, Object> integerTransform(BiConsumer<Value, Integer> consumer) {
        return (value, object) -> {
            if (object instanceof Integer) {
                consumer.accept(value, (Integer) object);
            } else if (object instanceof String) {
                consumer.accept(value, Integer.parseInt((String) object));
            } else {
                throw new IllegalArgumentException("Value must be a number, but is a " + object.getClass());
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

    public void integer(String name, BiConsumer<Value, Integer> consumer) {
        declareField(name, integerTransform(consumer));
    }

    public void string(String name, BiConsumer<Value, String> consumer) {
        declareField(name, stringTransform(consumer));
    }

    public <T> void object(String name, BiConsumer<Value, T> consumer, ConstructingObjectParser<T> parser) {
        declareField(name, (value, object) -> {
            if (object instanceof Map) {
                // XXX: Fix this unchecked cast.
                consumer.accept(value, parser.parse((Map<String, Object>) object));
            } else {
                throw new IllegalArgumentException("Object value must be a Map, but is a " + object.getClass());
            }
        });
    }

    public void declareField(String name, BiConsumer<Value, Object> consumer) {
        parsers.put(name, consumer);
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
    private class Field {
        String name;
        boolean isConstructorArg;
        BiConsumer<Value, Object> consumer;

        Field(String name, boolean isConstructorArg, BiConsumer<Value, Object> consumer) {
            this.name = name;
            this.isConstructorArg = isConstructorArg;
            this.consumer = consumer;
        }

        String getName() {
            return name;
        }

        BiConsumer<Value, Object> getConsumer() {
            return consumer;
        }

        boolean isConstructorArg() {
            return isConstructorArg;
        }

    }
}
