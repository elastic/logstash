package com.logstash;

import com.logstash.bivalues.BiValue;
import com.logstash.bivalues.BiValues;
import org.jruby.RubyArray;
import org.jruby.RubyHash;
import org.jruby.runtime.builtin.IRubyObject;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class Valuefier {
    private static final String PROXY_ERR_TEMPLATE = "Missing Ruby class handling for full class name=%s, simple name=%s, wrapped object=%s";
    private Valuefier(){}

    /*
        else if (o instanceof MapJavaProxy){
            return deepMap((Map)((MapJavaProxy) o).getObject());
        } else if (o instanceof ArrayJavaProxy || o instanceof ConcreteJavaProxy){
            return deepJavaProxy((JavaProxy) o);
        } else if (o instanceof RubyHash) {
            return deep((RubyHash) o);
        } else if (o instanceof RubyArray) {
            return deep((RubyArray) o);
        }
     */

    public static ConvertedMap rubyConvert(final RubyHash h) {
        final ConvertedMap<String, Object> result = new ConvertedMap<>();

        h.visitAll(new RubyHash.Visitor() {
            @Override
            public void visit(IRubyObject key, IRubyObject value) {
                String k = (String) BiValues.newBiValue(key).javaValue();
                result.put(k, convert(value));
            }
        });
        return result;
    }

    public static ConvertedList rubyConvert(final RubyArray a) {
        final ConvertedList<Object> result = new ConvertedList<>();

        for (IRubyObject o : a.toJavaArray()) {
            result.add(convert(o));
        }
        return result;
    }

    public static ConvertedMap javaConvert(final Map<String, Object> map) {
        ConvertedMap<String, Object> cm = new ConvertedMap<>();
        for (Map.Entry<String, Object> entry : map.entrySet()) {
            cm.put(entry.getKey(), convert(entry.getValue()));
        }
        return cm;
    }

    public static ConvertedList javaConvert(final List<Object> list) {
        ConvertedList<Object> array = new ConvertedList<>();

        for (Object item : list) {
            array.add(convert(item));
        }

        return array;
    }

    public static Object unconvertList(final ConvertedList<Object> list) {
        final ArrayList<Object> result = new ArrayList<>();

        for (Object o : list) {
            result.add(unconvert(o));
        }
        return result;
    }

    public static Object unconvertMap(final ConvertedMap<String, Object> map) {
        final HashMap<String, Object> result = new HashMap<>();

        for (Map.Entry<String, Object> entry : map.entrySet()) {
            result.put(entry.getKey(), unconvert(entry.getValue()));
        }

        return result;
    }

    public static Object unconvert(Object o) {
        if(o instanceof ConvertedList) {
            return unconvertMap((ConvertedMap) o);
        }
        if(o instanceof ConvertedList) {
            return unconvertList((ConvertedList) o);
        }
        if(o instanceof BiValue) {
            return ((BiValue) o).javaValue();
        }
        return o;
    }

    public static Object convertNonCollection(Object o) {
        try {
            return BiValues.newBiValue(o);
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("Missing Java class handling for full class name=" + o.getClass().getName() + ", simple name=" + o.getClass().getSimpleName());
        }
    }
    
    public static Object convert(Object o) {
        if (o instanceof ConvertedMap) {
            return o;
        }
        if (o instanceof ConvertedList) {
            return o;
        }
        if (o instanceof RubyHash) {
            return rubyConvert((RubyHash) o);
        }
        if (o instanceof RubyArray) {
            return rubyConvert((RubyArray) o);
        }
        if (o instanceof Map) {
            return javaConvert((Map<String, Object>) o);
        }
        if (o instanceof List) {
            return javaConvert((List<Object>) o);
        }
        if (o instanceof BiValue) {
            return o;
        }
        return convertNonCollection(o);
    }
}
