package org.logstash;

import java.util.Map;

public final class Accessors {

    private Accessors() {
        //Utility Class
    }

    public static Object get(final ConvertedMap data, final FieldReference field) {
        final Object target = findParent(data, field);
        return target == null ? null : fetch(target, field.getKey());
    }

    public static Object set(final ConvertedMap data, final FieldReference field,
        final Object value) {
        return setChild(findCreateTarget(data, field), field.getKey(), value);
    }

    public static Object del(final ConvertedMap data, final FieldReference field) {
        final Object target = findParent(data, field);
        if (target instanceof ConvertedMap) {
            return ((ConvertedMap) target).remove(field.getKey());
        } else {
            return target == null ? null : delFromList((ConvertedList) target, field.getKey());
        }
    }

    public static boolean includes(final ConvertedMap data, final FieldReference field) {
        final Object target = findParent(data, field);
        final String key = field.getKey();
        return target instanceof ConvertedMap && ((ConvertedMap) target).containsKey(key) ||
            target instanceof ConvertedList && foundInList(key, (ConvertedList) target);
    }

    private static Object delFromList(final ConvertedList list, final String key) {
        try {
            return list.remove(listIndex(key, list.size()));
        } catch (IndexOutOfBoundsException | NumberFormatException e) {
            return null;
        }
    }

    private static Object setOnList(final String key, final Object value, final ConvertedList list) {
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

    private static void appendAtIndex(final ConvertedList list, final Object value, final int index,
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

    private static Object findParent(final ConvertedMap data, final FieldReference field) {
        Object target = data;
        for (final String key : field.getPath()) {
            target = fetch(target, key);
            if (!(target instanceof ConvertedMap || target instanceof ConvertedList)) {
                return null;
            }
        }
        return target;
    }

    private static Object findCreateTarget(final ConvertedMap data, final FieldReference field) {
        Object target = data;
        boolean create = false;
        for (final String key : field.getPath()) {
            Object result;
            if (create) {
                result = createChild((ConvertedMap) target, key);
            } else {
                result = fetch(target, key);
                create = result == null;
                if (create) {
                    result = new ConvertedMap(1);
                    setChild(target, key, result);
                }
            }
            target = result;
        }
        return target;
    }

    private static Object setChild(final Object target, final String key, final Object value) {
        if (target instanceof Map) {
            ((ConvertedMap) target).put(key, value);
            return value;
        } else {
            return setOnList(key, value, (ConvertedList) target);
        }
    }

    private static Object createChild(final ConvertedMap target, final String key) {
        final Object result = new ConvertedMap(1);
        target.put(key, result);
        return result;
    }

    private static Object fetch(Object target, String key) {
        return target instanceof ConvertedMap
            ? ((ConvertedMap) target).get(key) : fetchFromList((ConvertedList) target, key);
    }

    private static Object fetchFromList(final ConvertedList list, final String key) {
        try {
            return list.get(listIndex(key, list.size()));
        } catch (IndexOutOfBoundsException | NumberFormatException e) {
            return null;
        }
    }

    private static boolean foundInList(final String key, final ConvertedList target) {
        return fetchFromList(target, key) != null;
    }

    /**
     * Returns a positive integer offset from a Ruby style positive or negative list index.
     * @param i List index
     * @param size the size of the list
     * @return the positive integer offset for the list given by index i
     */
    public static int listIndex(int i, int size) {
        return i < 0 ? size + i : i;
    }

    /**
     * Returns a positive integer offset for a list of known size.
     * @param key List index (String matching /[0-9]+/)
     * @param size the size of the list
     * @return the positive integer offset for the list given by index i
     */
    private static int listIndex(final String key, final int size) {
        return listIndex(Integer.parseInt(key), size);
    }
}
