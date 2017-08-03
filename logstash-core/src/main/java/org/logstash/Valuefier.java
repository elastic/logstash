package org.logstash;

import java.io.Serializable;
import java.util.List;
import java.util.Map;
import org.joda.time.DateTime;
import org.jruby.RubyArray;
import org.jruby.RubyHash;
import org.jruby.RubyString;
import org.jruby.RubyTime;
import org.jruby.java.proxies.ArrayJavaProxy;
import org.jruby.java.proxies.ConcreteJavaProxy;
import org.jruby.java.proxies.JavaProxy;
import org.jruby.java.proxies.MapJavaProxy;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.bivalues.BiValue;
import org.logstash.bivalues.BiValues;
import org.logstash.ext.JrubyTimestampExtLibrary;

public class Valuefier {
    private static final String PROXY_ERR_TEMPLATE = "Missing Valuefier handling for full class name=%s, simple name=%s, wrapped object=%s";
    private static final String ERR_TEMPLATE = "Missing Valuefier handling for full class name=%s, simple name=%s";

    private Valuefier(){}

    private static Object convertJavaProxy(JavaProxy jp) {
        if(jp == null) {
            return BiValues.NULL_BI_VALUE;
        }
        Object obj = JavaUtil.unwrapJavaObject(jp);
        if (obj instanceof IRubyObject[]) {
            return ConvertedList.newFromRubyArray((IRubyObject[]) obj);
        }
        if (obj instanceof List) {
            return ConvertedList.newFromList((List<Object>) obj);
        }
        try {
            return BiValues.newBiValue(jp);
        } catch (IllegalArgumentException e) {
            final Class<?> cls = obj.getClass();
            throw new IllegalArgumentException(String.format(PROXY_ERR_TEMPLATE, cls.getName(), cls.getSimpleName(), obj.getClass().getName()), e);
        }
    }

    public static Object convertNonCollection(Object o) {
        try {
            return o == null ? BiValues.NULL_BI_VALUE : BiValues.newBiValue(o);
        } catch (IllegalArgumentException e) {
            final Class<?> cls = o.getClass();
            throw new IllegalArgumentException(String.format(ERR_TEMPLATE, cls.getName(), cls.getSimpleName()), e);
        }
    }

    public static Object convert(Object o) throws IllegalArgumentException {
        if (o instanceof RubyString) {
            return o;
        }
        if (o instanceof String) {
            return BiValues.RUBY.newString((String) o);
        }
        if (o instanceof ConvertedMap || o instanceof ConvertedList) {
            return o;
        }
        if (o instanceof BiValue) {
            return o;
        }
        if (o instanceof RubyHash) {
            return ConvertedMap.newFromRubyHash((RubyHash) o);
        }
        if (o instanceof RubyArray) {
            return ConvertedList.newFromRubyArray((RubyArray) o);
        }
        if (o instanceof Map) {
            return ConvertedMap.newFromMap((Map<Serializable, Object>) o);
        }
        if (o instanceof List) {
            return ConvertedList.newFromList((List<Object>) o);
        }
        if (o instanceof MapJavaProxy){
            return ConvertedMap.newFromMap((Map)((MapJavaProxy) o).getObject());
        }
        if (o instanceof ArrayJavaProxy || o instanceof ConcreteJavaProxy){
            return convertJavaProxy((JavaProxy) o);
        }
        if (o instanceof RubyTime) {
            RubyTime time = (RubyTime) o;
            Timestamp ts = new Timestamp(time.getDateTime());
            JrubyTimestampExtLibrary.RubyTimestamp rts = JrubyTimestampExtLibrary.RubyTimestamp.newRubyTimestamp(time.getRuntime(), ts);
            return convertNonCollection(rts);
        }
        if (o instanceof DateTime) {
            Timestamp ts = new Timestamp((DateTime) o);
            return convertNonCollection(ts);
        }
        return convertNonCollection(o);
    }
}
