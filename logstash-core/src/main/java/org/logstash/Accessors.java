package org.logstash;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

public final class Accessors {

    private Accessors() {
        //Utility Class
    }

    public static Object get(final Map<String, Object> data, final String reference) {
        final FieldReference field = PathCache.cache(reference);
        final Object target = findParent(data, field);
        return target == null ? null : fetch(target, field.getKey());
    }

    public static Object set(final Map<String, Object> data, final String reference,
        final Object value) {
        final FieldReference field = PathCache.cache(reference);
        return setChild(findCreateTarget(data, field), field.getKey(), value);
    }

    public static Object del(final Map<String, Object> data, final String reference) {
        final FieldReference field = PathCache.cache(reference);
        final Object target = findParent(data, field);
        if (target instanceof Map) {
            return ((Map<String, Object>) target).remove(field.getKey());
        } else {
            return target == null ? null : delFromList((List<Object>) target, field.getKey());
        }
    }

    public static boolean includes(final Map<String, Object> data, final String reference) {
        final FieldReference field = PathCache.cache(reference);
        final Object target = findParent(data, field);
        final String key = field.getKey();
        return target instanceof Map && ((Map<String, Object>) target).containsKey(key) ||
            target instanceof List && foundInList(key, (List<Object>) target);
    }

    private static Object delFromList(final List<Object> list, final String key) {
        try {
            return list.remove(listIndex(key, list.size()));
        } catch (IndexOutOfBoundsException | NumberFormatException e) {
            return null;
        }
    }

    private static Object setOnList(final String key, final Object value, final List<Object> list) {
        final int index;
        try {
            index = Integer.parseInt(key);
        } catch (NumberFormatException e) {
            return null;
        }
        final int size = list.size();
        if (index >= size) {
            appendAtIndex(list, value, index, size);
        } else {
            list.set(listIndex(index, size), value);
        }
        return value;
    }

    private static void appendAtIndex(final List<Object> list, final Object value, final int index,
        final int size) {
        // grow array by adding trailing null items
        // this strategy reflects legacy Ruby impl behaviour and is backed by specs
        // TODO: (colin) this is potentially dangerous, and could produce OOM using arbitrary big numbers
        // TODO: (colin) should be guard against this?
        for (int i = size; i < index; i++) {
            list.add(null);
        }
        list.add(value);
    }

    private static Object findParent(final Map<String, Object> data, final FieldReference field) {
        Object target = data;
        for (final String key : field.getPath()) {
            target = fetch(target, key);
            if (!(target instanceof Map || target instanceof List)) {
                return null;
            }
        }
        return target;
    }

    private static Object findCreateTarget(final Map<String, Object> data,
        final FieldReference field) {
        Object target = data;
        boolean create = false;
        for (final String key : field.getPath()) {
            Object result;
            if (create) {
                result = createChild((Map<String, Object>) target, key);
            } else {
                result = fetch(target, key);
                create = result == null;
                if (create) {
                    result = new HashMap<String, Object>();
                    setChild(target, key, result);
                }
            }
            target = result;
        }
        return target;
    }

    private static Object setChild(final Object target, final String key, final Object value) {
        if (target instanceof Map) {
            ((Map<String, Object>) target).put(key, value);
            return value;
        } else {
            return setOnList(key, value, (List<Object>) target);
        }
    }

    private static Object createChild(final Map<String, Object> target, final String key) {
        final Object result = new HashMap<String, Object>();
        target.put(key, result);
        return result;
    }

    private static Object fetch(Object target, String key) {
        return target instanceof Map 
            ? ((Map<String, Object>) target).get(key) : fetchFromList((List<Object>) target, key);
    }

    private static Object fetchFromList(final List<Object> list, final String key) {
        try {
            return list.get(listIndex(key, list.size()));
        } catch (IndexOutOfBoundsException | NumberFormatException e) {
            return null;
        }
    }

    private static boolean foundInList(final String key, final List<Object> target) {
        return fetchFromList(target, key) != null;
    }

    /**
     * Returns a positive integer offset for a list of known size.
     * @param size the size of the list.
     * @return the positive integer offset for the list given by index i.
     */
    public static int listIndex(int i, int size) {
        return i < 0 ? size + i : i;
    }

    /**
     * Returns a positive integer offset for a list of known size.
     * @param size the size of the list.
     * @return the positive integer offset for the list given by index i.
     */
    private static int listIndex(final String key, final int size) {
        return listIndex(Integer.parseInt(key), size);
    }
}
