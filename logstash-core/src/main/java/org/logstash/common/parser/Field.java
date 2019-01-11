package org.logstash.common.parser;

import java.util.List;
import java.util.Map;
import java.util.function.Function;

public interface Field<Value> extends Function<Object, Value> {
    static <V> Field<V> declareObject(String name, ObjectFactory<V> parser) {
        return declareField(name, (config) -> parser.apply(ObjectTransforms.transformMap(config)));
    }

    String getName();

    String getDetails();

    static Field<String> declareString(String name) {
        return declareField(name, ObjectTransforms::transformString);
    }

    static Field<Float> declareFloat(String name) {
        return declareField(name, ObjectTransforms::transformFloat);
    }

    static Field<Long> declareLong(String name) {
        return declareField(name, ObjectTransforms::transformLong);
    }

    static Field<Double> declareDouble(String name) {
        return declareField(name, ObjectTransforms::transformDouble);
    }

    static Field<Boolean> declareBoolean(String name) {
        return declareField(name, ObjectTransforms::transformBoolean);
    }

    static Field<Integer> declareInteger(String name) {
        return declareField(name, ObjectTransforms::transformInteger);
    }

    static Field<Map<String, Object>> declareMap(String name) {
        return declareField(name, ObjectTransforms::transformMap);
    }

    default Value apply(Map<String, Object> map) {
        return apply(map.get(getName()));
    }

    static <V> Field<List<V>> declareList(String name, Function<Object, V> transform) {
        return new FieldDefinition<>(name, (object) -> ObjectTransforms.transformList(object, transform));
    }

    static <V> Field<V> declareField(String name, Function<Object, V> transform) {
        return new FieldDefinition<>(name, transform);
    }

}
