package org.logstash;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

class Accessors {

    private final ConvertedMap data;
    protected Map<String, Object> lut;

    public Accessors(final ConvertedMap data) {
        this.data = data;
        this.lut = new HashMap<>(); // reference -> target LUT
    }

    public Object get(String reference) {
        FieldReference field = PathCache.cache(reference);
        Object target = findTarget(field);
        return (target == null) ? null : fetch(target, field.getKey());
    }

    public Object set(String reference, Object value) {
        final FieldReference field = PathCache.cache(reference);
        final Object target = findCreateTarget(field);
        final String key = field.getKey();
        if (target instanceof ConvertedMap) {
            ((ConvertedMap) target).put(key, value);
        } else if (target instanceof ConvertedList) {
            int i;
            try {
                i = Integer.parseInt(key);
            } catch (NumberFormatException e) {
                return null;
            }
            int size = ((ConvertedList) target).size();
            if (i >= size) {
                // grow array by adding trailing null items
                // this strategy reflects legacy Ruby impl behaviour and is backed by specs
                // TODO: (colin) this is potentially dangerous, and could produce OOM using arbitrary big numbers
                // TODO: (colin) should be guard against this?
                for (int j = size; j < i; j++) {
                    ((List<Object>) target).add(null);
                }
                ((List<Object>) target).add(value);
            } else {
                int offset = listIndex(i, ((List) target).size());
                ((ConvertedList) target).set(offset, value);
            }
        } else {
            throw newCollectionException(target);
        }
        return value;
    }

    public Object del(String reference) {
        FieldReference field = PathCache.cache(reference);
        Object target = findTarget(field);
        if (target != null) {
            if (target instanceof ConvertedMap) {
                return ((ConvertedMap) target).remove(field.getKey());
            } else if (target instanceof ConvertedList) {
                try {
                    int i = Integer.parseInt(field.getKey());
                    int offset = listIndex(i, ((List) target).size());
                    return ((List)target).remove(offset);
                } catch (IndexOutOfBoundsException|NumberFormatException e) {
                    return null;
                }
            } else {
                throw newCollectionException(target);
            }
        }
        return null;
    }

    public boolean includes(String reference) {
        final FieldReference field = PathCache.cache(reference);
        final Object target = findTarget(field);
        final String key = field.getKey();
        return target instanceof ConvertedMap && ((ConvertedMap) target).containsKey(key) ||
            target instanceof ConvertedList && foundInList(key, (ConvertedList) target);
    }

    private static boolean foundInList(final String key, final ConvertedList target) {
        try {
            return foundInList(target, Integer.parseInt(key));
        } catch (NumberFormatException e) {
            return false;
        }
    }

    private Object findTarget(FieldReference field) {
        final Object target = this.lut.get(field.getReference());
        return target != null ? target : cacheTarget(field);
    }

    private Object cacheTarget(final FieldReference field) {
        Object target = this.data;
        for (final String key : field.getPath()) {
            target = fetch(target, key);
            if (!isCollection(target)) {
                return null;
            }
        }
        this.lut.put(field.getReference(), target);
        return target;
    }

    private Object findCreateTarget(FieldReference field) {
        Object target;

        // flush the @lut to prevent stale cached fieldref which may point to an old target
        // which was overwritten with a new value. for example, if "[a][b]" is cached and we
        // set a new value for "[a]" then reading again "[a][b]" would point in a stale target.
        // flushing the complete @lut is suboptimal, but a hierarchical lut would be required
        // to be able to invalidate fieldrefs from a common root.
        // see https://github.com/elastic/logstash/pull/5132
        this.lut.clear();

        target = this.data;
        for (String key : field.getPath()) {
            Object result = fetch(target, key);
            if (result == null) {
                result = new ConvertedMap(1);
                if (target instanceof ConvertedMap) {
                    ((ConvertedMap) target).put(key, result);
                } else if (target instanceof ConvertedList) {
                    try {
                        int i = Integer.parseInt(key);
                        // TODO: what about index out of bound?
                        ((ConvertedList) target).set(i, result);
                    } catch (NumberFormatException e) {
                        continue;
                    }
                } else if (target != null) {
                    throw newCollectionException(target);
                }
            }
            target = result;
        }

        this.lut.put(field.getReference(), target);

        return target;
    }

    private static boolean foundInList(ConvertedList target, int index) {
        try {
            int offset = listIndex(index, target.size());
            return target.get(offset) != null;
        } catch (IndexOutOfBoundsException e) {
            return false;
        }

    }

    private static Object fetch(Object target, String key) {
        if (target instanceof ConvertedMap) {
            return ((ConvertedMap) target).get(key);
        } else if (target instanceof ConvertedList) {
            try {
                int offset = listIndex(Integer.parseInt(key), ((ConvertedList) target).size());
                return ((ConvertedList) target).get(offset);
            } catch (IndexOutOfBoundsException|NumberFormatException e) {
                return null;
            }
        } else if (target == null) {
            return null;
        } else {
            throw newCollectionException(target);
        }
    }

    private static boolean isCollection(Object target) {
        return target instanceof ConvertedList || target instanceof ConvertedMap;
    }

    private static ClassCastException newCollectionException(Object target) {
        return new ClassCastException("expecting ConvertedList or ConvertedMap, found "  + target.getClass());
    }

    /* 
     * Returns a positive integer offset for a list of known size.
     *
     * @param i if positive, and offset from the start of the list. If negative, the offset from the end of the list, where -1 means the last element.
     * @param size the size of the list.
     * @return the positive integer offset for the list given by index i.
     */
    public static int listIndex(int i, int size) {
        if (i >= size || i < -size) {
            throw new IndexOutOfBoundsException("Index " + i + " is out of bounds for a list with size " + size);
        }

        if (i < 0) { // Offset from the end of the array.
            return size + i;
        } else {
            return i;
        }
    }
}
