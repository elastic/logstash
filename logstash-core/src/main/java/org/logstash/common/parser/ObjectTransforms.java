package org.logstash.common.parser;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.function.Function;

public class ObjectTransforms {
    /**
     * A function which takes an Object and returns an Integer
     *
     * @param object the object to transform to Integer
     * @return An Integer based on the given object.
     * @throws IllegalArgumentException if conversion is not possible
     */
    @SuppressWarnings("WeakerAccess") // Public Interface
    public static Integer transformInteger(Object object) throws IllegalArgumentException {
        if (object instanceof Number) {
            return ((Number) object).intValue();
        } else if (object instanceof String) {
            return Integer.parseInt((String) object);
        } else {
            throw new IllegalArgumentException("Value must be a number, but is a " + object.getClass());
        }
    }

    @SuppressWarnings("WeakerAccess") // Public Interface
    public static Float transformFloat(Object object) throws IllegalArgumentException {
        if (object instanceof Number) {
            return ((Number) object).floatValue();
        } else if (object instanceof String) {
            return Float.parseFloat((String) object);
        } else {
            throw new IllegalArgumentException("Value must be a number, but is a " + object.getClass());
        }
    }

    @SuppressWarnings("WeakerAccess") // Public Interface
    public static Double transformDouble(Object object) throws IllegalArgumentException {
        if (object instanceof Number) {
            return ((Number) object).doubleValue();
        } else if (object instanceof String) {
            return Double.parseDouble((String) object);
        } else {
            throw new IllegalArgumentException("Value must be a number, but is a " + object.getClass());
        }
    }

    @SuppressWarnings("WeakerAccess") // Public Interface
    public static Long transformLong(Object object) throws IllegalArgumentException {
        if (object instanceof Number) {
            return ((Number) object).longValue();
        } else if (object instanceof String) {
            return Long.parseLong((String) object);
        } else {
            throw new IllegalArgumentException("Value must be a number, but is a " + object.getClass());
        }
    }

    @SuppressWarnings("WeakerAccess") // Public Interface
    public static String transformString(Object object) throws IllegalArgumentException {
        if (object instanceof String) {
            return (String) object;
        } else if (object instanceof Number) {
            return object.toString();
        } else {
            throw new IllegalArgumentException("Value must be a string, but is a " + object.getClass());
        }
    }

    @SuppressWarnings("WeakerAccess") // Public Interface
    public static Boolean transformBoolean(Object object) throws IllegalArgumentException {
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
    public static <T> T transformObject(Object object, ObjectFactory<T> parser) throws IllegalArgumentException {
        if (object instanceof Map) {
            // XXX: Fix this unchecked cast.
            return parser.apply((Map<String, Object>) object);
        } else {
            throw new IllegalArgumentException("Object value must be a Map, but is a " + object.getClass());
        }
    }

    @SuppressWarnings("WeakerAccess") // Public Interface
    public static <T> List<T> transformList(Object object, Function<Object, T> transform) throws IllegalArgumentException {
        // XXX: Support Iterator?
        if (object instanceof List) {
            List<Object> list = (List<Object>) object;
            List<T> result = new ArrayList<>(list.size());
            list.stream().map(transform).forEach(result::add);
            return result;
        } else {
            throw new IllegalArgumentException("Object value must be a List, but is a " + object.getClass());
        }
    }

    @SuppressWarnings("WeakerAccess") // Public Interface
    public static Map<String, Object> transformMap(Object object) {
        if (object instanceof Map) {
            // XXX: Validate all entries in this map for the cast?
            return (Map<String, Object>) object;
        } else {
            throw new IllegalArgumentException("Expected a map `{ ... }` but got a " + object.getClass());
        }
    }
}
