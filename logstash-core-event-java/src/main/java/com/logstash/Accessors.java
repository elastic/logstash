package com.logstash;

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
                if (i < 0 || i >= ((List) target).size()) {
                    return null;
                }
                return ((List<Object>) target).remove(i);
            } else {
                throw new ClassCastException("expecting List or Map");
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
            if (target == null) {
                return null;
            }
        }

        this.lut.put(field.getReference(), target);

        return target;
    }

    private Object findCreateTarget(FieldReference field) {
        Object target;

        if ((target = this.lut.get(field.getReference())) != null) {
            return target;
        }

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
                } else if (target == null) {
                    // do nothing
                } else {
                    throw new ClassCastException("expecting List or Map");
                }
            }
            target = result;
        }

        this.lut.put(field.getReference(), target);

        return target;
    }

    private boolean foundInList(List<Object> target, int index) {
        if (index < 0 || index >= target.size()) {
            return false;
        }
        return target.get(index) != null;
    }

    private boolean foundInMap(Map<String, Object> target, String key) {
        return target.containsKey(key);
    }

    private Object fetch(Object target, String key) {
        if (target instanceof Map) {
            Object result = ((Map<String, Object>) target).get(key);
            return result;
        } else if (target instanceof List) {
            int i = Integer.parseInt(key);
            if (i < 0 || i >= ((List) target).size()) {
                return null;
            }
            Object result = ((List<Object>) target).get(i);
            return result;
        } else if (target == null) {
            return null;
        } {
            throw new ClassCastException("expecting List or Map");
        }
    }

    private Object store(Object target, String key, Object value) {
        if (target instanceof Map) {
            ((Map<String, Object>) target).put(key, value);
        } else if (target instanceof List) {
            int i = Integer.parseInt(key);
            // TODO: what about index out of bound?
            ((List<Object>) target).set(i, value);
        } else {
            throw new ClassCastException("expecting List or Map");
        }
        return value;
    }
}
