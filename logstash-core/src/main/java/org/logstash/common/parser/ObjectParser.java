package org.logstash.common.parser;

import java.util.List;
import java.util.Map;
import java.util.function.BiConsumer;
import java.util.function.Function;

public interface ObjectParser<Value> extends Function<Map<String, Object>, Value> {
    <T> Field declareField(String name, BiConsumer<Value, T> consumer, Function<Object, T> transform);

    <T> Field declareConstructorArg(String name, Function<Object, T> transform);

    /**
     * Add an field with an long value.
     *
     * @param name     the name of this field
     * @param consumer the function to call once the value is available
     */
    default Field declareLong(String name, BiConsumer<Value, Long> consumer) {
        return declareField(name, consumer, ObjectTransforms::transformLong);
    }

    /**
     * Declare an long constructor argument.
     *
     * @param name the name of the field.
     */
    default Field declareLong(String name) {
        return declareConstructorArg(name, ObjectTransforms::transformLong);
    }

    /**
     * Add an field with an integer value.
     *
     * @param name     the name of this field
     * @param consumer the function to call once the value is available
     */
    default Field declareInteger(String name, BiConsumer<Value, Integer> consumer) {
        return declareField(name, consumer, ObjectTransforms::transformInteger);
    }

    /**
     * Declare an integer constructor argument.
     *
     * @param name the name of the field.
     */
    default Field declareInteger(String name) {
        return declareConstructorArg(name, ObjectTransforms::transformInteger);
    }

    /**
     * Add a field with a string value.
     *
     * @param name     the name of this field
     * @param consumer the function to call once the value is available
     */
    default Field declareString(String name, BiConsumer<Value, String> consumer) {
        return declareField(name, consumer, ObjectTransforms::transformString);
    }

    /**
     * Declare a constructor argument that is a string.
     *
     * @param name the name of this field.
     */
    default Field declareString(String name) {
        return declareConstructorArg(name, ObjectTransforms::transformString);
    }

    /**
     * Declare a field with a List containing T instances
     *
     * @param name      the name of this field
     * @param consumer  the consumer to call when this field is processed
     * @param transform the function for transforming Object to T types
     * @param <T>       the type stored in the List.
     */
    default <T> Field declareList(String name, BiConsumer<Value, List<T>> consumer, Function<Object, T> transform) {
        return declareField(name, consumer, object -> ObjectTransforms.transformList(object, transform));
    }

    /**
     * Declare a constructor argument which is a List
     *
     * @param name      The name of the argument.
     * @param transform The object -> T transform function
     * @param <T>       The type of object contained in the list.
     */
    default <T> Field declareList(String name, Function<Object, T> transform) {
        return declareConstructorArg(name, (object) -> ObjectTransforms.transformList(object, transform));
    }

    /**
     * Declare a constructor argument that is a float.
     *
     * @param name the name of the argument
     */
    default Field declareFloat(String name) {
        return declareConstructorArg(name, ObjectTransforms::transformFloat);
    }

    default Field declareFloat(String name, BiConsumer<Value, Float> consumer) {
        return declareField(name, consumer, ObjectTransforms::transformFloat);
    }

    default Field declareDouble(String name) {
        return declareConstructorArg(name, ObjectTransforms::transformDouble);
    }

    default Field declareDouble(String name, BiConsumer<Value, Double> consumer) {
        return declareField(name, consumer, ObjectTransforms::transformDouble);
    }

    default Field declareBoolean(String name) {
        return declareConstructorArg(name, ObjectTransforms::transformBoolean);
    }

    default Field declareBoolean(String name, BiConsumer<Value, Boolean> consumer) {
        return declareField(name, consumer, ObjectTransforms::transformBoolean);
    }

    /**
     * Add a field with an object value
     *
     * @param name     the name of this field
     * @param consumer the function to call once the value is available
     * @param parser   The ConstructingObjectParser that will build the object
     * @param <T>      The type of object to store as the value.
     */
    default <T> Field declareObject(String name, BiConsumer<Value, T> consumer, ConstructingObjectParser<T> parser) {
        return declareField(name, consumer, (t) -> ObjectTransforms.transformObject(t, parser));
    }

    /**
     * Declare a constructor argument that is an object.
     *
     * @param name   the name of the field which represents this constructor argument
     * @param parser the ConstructingObjectParser that builds the object
     * @param <T>    The type of object created by the parser.
     */
    default <T> Field declareObject(String name, ConstructingObjectParser<T> parser) {
        return declareConstructorArg(name, (t) -> ObjectTransforms.transformObject(t, parser));
    }

}
