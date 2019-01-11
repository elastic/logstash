package org.logstash.common.parser;

import org.logstash.common.parser.Functions.Function3;
import org.logstash.common.parser.Functions.Function4;
import org.logstash.common.parser.Functions.Function5;
import org.logstash.common.parser.Functions.Function6;
import org.logstash.common.parser.Functions.Function7;
import org.logstash.common.parser.Functions.Function8;
import org.logstash.common.parser.Functions.Function9;

import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.function.BiConsumer;
import java.util.function.BiFunction;
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
public class ObjectFactory<Value> implements Function<Map<String, Object>, Value> {
    private final Map<String, BiConsumer<Value, Object>> parsers = new HashMap<>();
    private List<Field<?>> constructorFields;
    private final Function<Map<String, Object>, Value> builder;

    /**
     * Zero-argument object constructor (A Supplier)
     *
     * @param supplier The supplier which produces an object instance.
     */
    @SuppressWarnings("WeakerAccess") // Public Interface
    public ObjectFactory(Supplier<Value> supplier) {
        this(config -> supplier.get());
        constructorFields = Collections.emptyList();
    }

    /**
     * One-argument object constructor
     */
    @SuppressWarnings("WeakerAccess") // Public Interface
    public <Arg0> ObjectFactory(Function<Arg0, Value> function, Field<Arg0> arg0) {
        this(config -> function.apply(arg0.apply(config)));
        constructorFields = Collections.singletonList(arg0);
    }

    /**
     * Two-argument object constructor
     */
    @SuppressWarnings("WeakerAccess") // Public Interface
    public <Arg0, Arg1> ObjectFactory(BiFunction<Arg0, Arg1, Value> function, Field<Arg0> arg0, Field<Arg1> arg1) {
        this(config -> function.apply(arg0.apply(config), arg1.apply(config)));
        constructorFields = Arrays.asList(arg0, arg1);
    }

    /**
     * Three-argument object constructor
     */
    @SuppressWarnings("WeakerAccess") // Public Interface
    public <Arg0, Arg1, Arg2> ObjectFactory(Function3<Arg0, Arg1, Arg2, Value> function, Field<Arg0> arg0, Field<Arg1> arg1, Field<Arg2> arg2) {
        this(config -> function.apply(arg0.apply(config), arg1.apply(config), arg2.apply(config)));
        constructorFields = Arrays.asList(arg0, arg1, arg2);
    }


    @SuppressWarnings("WeakerAccess") // Public Interface
    public <Arg0, Arg1, Arg2, Arg3> ObjectFactory(Function4<Arg0, Arg1, Arg2, Arg3, Value> function, Field<Arg0> arg0, Field<Arg1> arg1, Field<Arg2> arg2, Field<Arg3> arg3) {
        this(config -> function.apply(arg0.apply(config), arg1.apply(config), arg2.apply(config), arg3.apply(config)));
        constructorFields = Arrays.asList(arg0, arg1, arg2, arg3);
    }

    @SuppressWarnings("WeakerAccess") // Public Interface
    public <Arg0, Arg1, Arg2, Arg3, Arg4> ObjectFactory(Function5<Arg0, Arg1, Arg2, Arg3, Arg4, Value> function, Field<Arg0> arg0, Field<Arg1> arg1, Field<Arg2> arg2, Field<Arg3> arg3, Field<Arg4> arg4) {
        this(config -> function.apply(arg0.apply(config), arg1.apply(config), arg2.apply(config), arg3.apply(config), arg4.apply(config)));
        constructorFields = Arrays.asList(arg0, arg1, arg2, arg3, arg4);
    }

    @SuppressWarnings("WeakerAccess") // Public Interface
    public <Arg0, Arg1, Arg2, Arg3, Arg4, Arg5> ObjectFactory(Function6<Arg0, Arg1, Arg2, Arg3, Arg4, Arg5, Value> function, Field<Arg0> arg0, Field<Arg1> arg1, Field<Arg2> arg2, Field<Arg3> arg3, Field<Arg4> arg4, Field<Arg5> arg5) {
        this(config -> function.apply(arg0.apply(config), arg1.apply(config), arg2.apply(config), arg3.apply(config), arg4.apply(config), arg5.apply(config)));
        constructorFields = Arrays.asList(arg0, arg1, arg2, arg3, arg4, arg5);
    }

    @SuppressWarnings("WeakerAccess") // Public Interface
    public <Arg0, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6> ObjectFactory(Function7<Arg0, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Value> function, Field<Arg0> arg0, Field<Arg1> arg1, Field<Arg2> arg2, Field<Arg3> arg3, Field<Arg4> arg4, Field<Arg5> arg5, Field<Arg6> arg6) {
        this(config -> function.apply(arg0.apply(config), arg1.apply(config), arg2.apply(config), arg3.apply(config), arg4.apply(config), arg5.apply(config), arg6.apply(config)));
        constructorFields = Arrays.asList(arg0, arg1, arg2, arg3, arg4, arg5, arg6);
    }

    @SuppressWarnings("WeakerAccess") // Public Interface
    public <Arg0, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7> ObjectFactory(Function8<Arg0, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7, Value> function, Field<Arg0> arg0, Field<Arg1> arg1, Field<Arg2> arg2, Field<Arg3> arg3, Field<Arg4> arg4, Field<Arg5> arg5, Field<Arg6> arg6, Field<Arg7> arg7) {
        this(config -> function.apply(arg0.apply(config), arg1.apply(config), arg2.apply(config), arg3.apply(config), arg4.apply(config), arg5.apply(config), arg6.apply(config), arg7.apply(config)));
        constructorFields = Arrays.asList(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7);
    }

    @SuppressWarnings("WeakerAccess") // Public Interface
    public <Arg0, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7, Arg8> ObjectFactory(Function9<Arg0, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7, Arg8, Value> function, Field<Arg0> arg0, Field<Arg1> arg1, Field<Arg2> arg2, Field<Arg3> arg3, Field<Arg4> arg4, Field<Arg5> arg5, Field<Arg6> arg6, Field<Arg7> arg7, Field<Arg8> arg8) {
        this(config -> function.apply(arg0.apply(config), arg1.apply(config), arg2.apply(config), arg3.apply(config), arg4.apply(config), arg5.apply(config), arg6.apply(config), arg7.apply(config), arg8.apply(config)));
        constructorFields = Arrays.asList(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8);
    }

    private ObjectFactory(Function<Map<String, Object>, Value> builder) {
        this.builder = builder;
    }

    /**
     * Use the given config to produce the Value object.
     * <p>
     * Contract:
     * 1) All declared constructor arguments are required. If any are missing, an IllegalArgumentException is thrown.
     * 2) All declared fields are optional.
     * 3) Any unknown fields found will cause this method to throw an IllegalArgumentException.
     * 4) If any field processing fails, an IllegalArgumentException is thrown
     *
     * @param config the configuration
     * @return the configured object
     */
    @SuppressWarnings("WeakerAccess") // Public Interface
    public Value apply(Map<String, Object> config) {
        rejectUnknownFields(config.keySet());

        Value value = this.builder.apply(config);

        // Now call all the object setters/etc
        for (Map.Entry<String, Object> entry : config.entrySet()) {
            String name = entry.getKey();
            if (isConstructorField(name)) {
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

    private boolean isConstructorField(String name) {
        return constructorFields.stream().anyMatch(f -> f.getName().equals(name));
    }

    private boolean isKnownField(String name) {
        return parsers.containsKey(name) || isConstructorField(name);
    }


    private void rejectUnknownFields(Set<String> configNames) throws IllegalArgumentException {
        // Check for any unknown parameters.
        List<String> unknown = configNames.stream().filter(name -> !isKnownField(name)).collect(Collectors.toList());

        if (!unknown.isEmpty()) {
            throw new IllegalArgumentException("Unknown settings: " + unknown);
        }
    }

    @SuppressWarnings("WeakerAccess") // Public Interface
    public <T> ObjectFactory<Value> define(Field<T> field, BiConsumer<Value, T> consumer) {
        if (isKnownField(field.getName())) {
            throw new IllegalArgumentException("Duplicate field defined '" + field.getName() + "'");
        }

        parsers.put(field.getName(), (value, input) -> consumer.accept(value, field.apply(input)));
        return this;
    }

    @SuppressWarnings("WeakerAccess") // Public Interface
    public <T> ObjectFactory<Value> deprecate(Field<T> field, BiConsumer<Value, T> consumer, String details) {
        return define(new DeprecatedField<>(field.getName(), field, details), consumer);
    }

    @SuppressWarnings("WeakerAccess") // Public Interface
    public <T> ObjectFactory<Value> obsolete(Field<T> field, BiConsumer<Value, T> consumer, String details) {
        return define(new ObsoleteField<>(field.getName(), field, details), consumer);
    }
}
