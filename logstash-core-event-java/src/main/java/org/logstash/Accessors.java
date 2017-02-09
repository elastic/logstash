package org.logstash;

import java.util.HashMap;
import java.util.Map;
import java.util.List;

public class Accessors {

    private Map<String, Object> data;
    protected Map<String, Object> lut;

    public Accessors(Map<String, Object> data) {
        this.data = data;
        this.lut = new HashMap<>(); // reference -> target LUT
    }

    public Object get(String reference) {
        FieldReference field = PathCache.getInstance().cache(reference);
        Object target = findTarget(field);
        return (target == null) ? null : fetch(target, field.getKey());
    }

    public Object set(String reference, Object value) {
        FieldReference field = PathCache.getInstance().cache(reference);
        Object target = findCreateTarget(field);
        return store(target, field.getKey(), value);
    }

    public Object del(String reference) {
        FieldReference field = PathCache.getInstance().cache(reference);
        Object target = findTarget(field);
        if (target != null) {
            if (target instanceof Map) {
                return ((Map<String, Object>) target).remove(field.getKey());
            } else if (target instanceof List) {
                int i = Integer.parseInt(field.getKey());
                try {
                    int offset = listIndex(i, ((List) target).size());
                    return ((List)target).remove(offset);
                } catch (IndexOutOfBoundsException e) {
                    return null;
                }
            } else {
                throw newCollectionException(target);
            }
        }
        return null;
    }

    public boolean includes(String reference) {
        FieldReference field = PathCache.getInstance().cache(reference);
        Object target = findTarget(field);
        if (target instanceof Map && foundInMap((Map<String, Object>) target, field.getKey())) {
            return true;
        } else if (target instanceof List && foundInList((List<Object>) target, Integer.parseInt(field.getKey()))) {
            return true;
        } else {
            return false;
        }
    }

    private Object findTarget(FieldReference field) {
        Object target;

        if ((target = this.lut.get(field.getReference())) != null) {
            return target;
        }

        target = this.data;
        for (String key : field.getPath()) {
            target = fetch(target, key);
            if (! isCollection(target)) {
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
                result = new HashMap<String, Object>();
                if (target instanceof Map) {
                    ((Map<String, Object>)target).put(key, result);
                } else if (target instanceof List) {
                    int i = Integer.parseInt(key);
                    // TODO: what about index out of bound?
                    ((List<Object>)target).set(i, result);
                } else if (target != null) {
                    throw newCollectionException(target);
                }
            }
            target = result;
        }

        this.lut.put(field.getReference(), target);

        return target;
    }

    private boolean foundInList(List<Object> target, int index) {
        try {
            int offset = listIndex(index, target.size());
            return target.get(offset) != null;
        } catch (IndexOutOfBoundsException e) {
            return false;
        }

    }

    private boolean foundInMap(Map<String, Object> target, String key) {
        return target.containsKey(key);
    }

    private Object fetch(Object target, String key) {
        if (target instanceof Map) {
            Object result = ((Map<String, Object>) target).get(key);
            return result;
        } else if (target instanceof List) {
            try {
                int offset = listIndex(Integer.parseInt(key), ((List) target).size());
                return ((List<Object>) target).get(offset);
            } catch (IndexOutOfBoundsException e) {
                return null;
            }
        } else if (target == null) {
            return null;
        } else {
            throw newCollectionException(target);
        }
    }

    private Object store(Object target, String key, Object value) {
        if (target instanceof Map) {
            ((Map<String, Object>) target).put(key, value);
        } else if (target instanceof List) {
            int i = Integer.parseInt(key);
            int size = ((List<Object>) target).size();
            if (i >= size) {
                // grow array by adding trailing null items
                // this strategy reflects legacy Ruby impl behaviour and is backed by specs
                // TODO: (colin) this is potentially dangerous, and could produce OOM using arbritary big numbers
                // TODO: (colin) should be guard against this?
                for (int j = size; j < i; j++) {
                    ((List<Object>) target).add(null);
                }
                ((List<Object>) target).add(value);
            } else {
                int offset = listIndex(i, ((List) target).size());
                ((List<Object>) target).set(offset, value);
            }
        } else {
            throw newCollectionException(target);
        }
        return value;
    }

    private boolean isCollection(Object target) {
        if (target == null) {
            return false;
        }
        return (target instanceof Map || target instanceof List);
    }

    private ClassCastException newCollectionException(Object target) {
        return new ClassCastException("expecting List or Map, found "  + target.getClass());
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
