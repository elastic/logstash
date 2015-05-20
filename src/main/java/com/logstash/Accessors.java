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
        // TODO: implement
        return null;
    }

    public boolean includes(String reference) {
        FieldReference field = PathCache.getInstance().cache(reference);
        Object target = findTarget(field);
        return (target == null) ? false : (fetch(target, field.getKey()) != null);
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
                } else {
                    throw new ClassCastException("expecting List or Map");
                }
            }
            target = result;
        }

        this.lut.put(field.getReference(), target);

        return target;
    }

    private Object fetch(Object target, String key) {
        if (target instanceof Map) {
            Object result = ((Map<String, Object>) target).get(key);
//            if (result != null) {
//                System.out.println("fetch class=" + result.getClass().getName() + ", toString=" + result.toString());
//            }
            return result;
        } else if (target instanceof List) {
            int i = Integer.parseInt(key);
            if (i < 0 || i >= ((List) target).size()) {
                return null;
            }
            Object result = ((List<Object>) target).get(i);
//            if (result != null) {
//                System.out.println("fetch class=" + result.getClass().getName() + ", toString=" + result.toString());
//            }
            return result;
        } else {
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
