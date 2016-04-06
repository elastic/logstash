package com.logstash;

import org.jruby.RubyArray;
import org.jruby.RubyHash;
import org.jruby.runtime.builtin.IRubyObject;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class Valuefier {

    private Valuefier(){}

    public static List<Object> rubyConvert(final RubyArray a) {
        final ArrayList<Object> result = new ArrayList();

        for (IRubyObject o : a.toJavaArray()) {
            result.add(convert(o));
        }
        return result;
    }

    public static HashMap<String, Object> rubyConvert(final RubyHash h) {
        final HashMap result = new HashMap();

        h.visitAll(new RubyHash.Visitor() {
            @Override
            public void visit(IRubyObject key, IRubyObject value) {
                result.put(Javafier.deep(key).toString(), convert(value));
            }
        });
        return result;
    }

    public static HashMap<String, Object> javaConvert(final Map<String, Object> map) {
        HashMap hash = new HashMap();
        for (Map.Entry<String, Object> entry : map.entrySet()) {
            hash.put(entry.getKey(), convert(entry.getValue()));
        }

        return hash;
    }

    public static List<Object> javaConvert(final List<Object> list) {
        ArrayList<Object> array = new ArrayList();

        for (Object item : list) {
            array.add(convert(item));
        }

        return array;
    }

    public static Object unconvertList(final List<Object> list) {
        final ArrayList<Object> result = new ArrayList();

        for (Object o : list) {
            result.add(unconvert(o));
        }
        return result;
    }

    public static Object unconvertMap(final Map<String, Object> map) {
        final HashMap<String, Object> result = new HashMap<>();

        for (Map.Entry<String, Object> entry : map.entrySet()) {
            result.put(entry.getKey(), convert(entry.getValue()));
        }

        return result;
    }
    public static Object unconvert(Object o) {
        if(o instanceof Map) {
            return unconvertMap((Map<String, Object>) o);
        }
        if(o instanceof List) {
            return unconvertList((List<Object>) o);
        }
        if(o instanceof RubyJavaObject) {
            return ((RubyJavaObject) o).getJavaValue();
        }
        return o;
    }

    public static Object convert(Object o) {
        if(o instanceof RubyHash) {
            return rubyConvert((RubyHash) o);
        }
        if(o instanceof RubyArray) {
            return rubyConvert((RubyArray) o);
        }
        if(o instanceof Map) {
            return javaConvert((Map<String, Object>) o);
        }
        if(o instanceof List) {
            return javaConvert((List<Object>) o);
        }
        if(o instanceof IRubyObject) {
            return new RubyJavaObject((IRubyObject) o);
        }
        return new RubyJavaObject(o);
    }
}
