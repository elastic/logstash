package org.logstash;

import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import org.joda.time.DateTime;
import org.jruby.RubyArray;
import org.jruby.RubyBoolean;
import org.jruby.RubyFixnum;
import org.jruby.RubyFloat;
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

public final class Valuefier {

    public static final Valuefier.Converter IDENTITY = input -> input;

    private static final Valuefier.Converter FLOAT_CONVERTER =
        input -> RubyUtil.RUBY.newFloat(((Number) input).doubleValue());

    private static final Valuefier.Converter LONG_CONVERTER
        = input -> RubyUtil.RUBY.newFixnum(((Number) input).longValue());

    private static final Valuefier.Converter JAVAPROXY_CONVERTER =
        input -> {
            final Object obj = JavaUtil.unwrapJavaObject((JavaProxy) input);
            if (obj instanceof IRubyObject[]) {
                return ConvertedList.newFromRubyArray((IRubyObject[]) obj);
            }
            if (obj instanceof List) {
                return ConvertedList.newFromList((Collection<?>) obj);
            }
            try {
                return BiValues.newBiValue(input);
            } catch (IllegalArgumentException e) {
                final Class<?> cls = obj.getClass();
                throw new IllegalArgumentException(String.format(
                    "Missing Valuefier handling for full class name=%s, simple name=%s, wrapped object=%s",
                    cls.getName(), cls.getSimpleName(), obj.getClass().getName()
                ), e);
            }
        };

    private static final Valuefier.Converter BIVALUES_CONVERTER = BiValues::newBiValue;

    private static final Map<Class<?>, Valuefier.Converter> CONVERTER_MAP = initConverters();

    private Valuefier() {
    }

    public static Object convert(final Object o) {
        if (o == null) {
            return BiValues.NULL_BI_VALUE;
        }
        final Class<?> cls = o.getClass();
        final Valuefier.Converter converter = CONVERTER_MAP.get(cls);
        if (converter != null) {
            return converter.convert(o);
        }
        return fallbackConvert(o, cls);
    }

    /**
     * Fallback for types not covered by {@link Valuefier#convert(Object)} as a result of no
     * {@link Valuefier.Converter} having been cached for the given class. Uses the fact that
     * the only subclasses of the keys in {@link Valuefier#CONVERTER_MAP} as set up by
     * {@link Valuefier#initConverters()} can be converted here and hence find the appropriate
     * super class for unknown types by checking each entry in {@link Valuefier#CONVERTER_MAP} for
     * being a supertype of the given class. If this fails {@link Valuefier#BIVALUES_CONVERTER}
     * will be cached and used.
     * @param o Object to convert
     * @param cls Class of given object {@code o}
     * @return Conversion result equivalent to what {@link Valuefier#convert(Object)} would return
     */
    private static Object fallbackConvert(final Object o, final Class<?> cls) {
        for (final Map.Entry<Class<?>, Valuefier.Converter> entry : CONVERTER_MAP.entrySet()) {
            if (entry.getKey().isAssignableFrom(cls)) {
                final Valuefier.Converter found = entry.getValue();
                CONVERTER_MAP.put(cls, found);
                return found.convert(o);
            }
        }
        CONVERTER_MAP.put(cls, BIVALUES_CONVERTER);
        return BIVALUES_CONVERTER.convert(o);
    }

    private static Map<Class<?>, Valuefier.Converter> initConverters() {
        final Map<Class<?>, Valuefier.Converter> converters =
            new ConcurrentHashMap<>(50, 0.2F, 1);
        converters.put(RubyString.class, IDENTITY);
        converters.put(RubyFixnum.class, IDENTITY);
        converters.put(JrubyTimestampExtLibrary.RubyTimestamp.class, IDENTITY);
        converters.put(RubyFloat.class, IDENTITY);
        converters.put(ConvertedMap.class, IDENTITY);
        converters.put(ConvertedList.class, IDENTITY);
        converters.put(RubyBoolean.class, IDENTITY);
        converters.put(BiValue.class, IDENTITY);
        converters.put(String.class, input -> RubyUtil.RUBY.newString((String) input));
        converters.put(Float.class, FLOAT_CONVERTER);
        converters.put(Double.class, FLOAT_CONVERTER);
        converters.put(Long.class, LONG_CONVERTER);
        converters.put(Integer.class, LONG_CONVERTER);
        converters.put(Boolean.class, input -> RubyUtil.RUBY.newBoolean((Boolean) input));
        converters.put(
            Timestamp.class,
            input -> JrubyTimestampExtLibrary.RubyTimestamp.newRubyTimestamp(
                RubyUtil.RUBY, (Timestamp) input
            )
        );
        converters.put(
            RubyTime.class, input -> JrubyTimestampExtLibrary.RubyTimestamp.newRubyTimestamp(
                RubyUtil.RUBY, new Timestamp(((RubyTime) input).getDateTime())
            )
        );
        converters.put(
            DateTime.class, input -> JrubyTimestampExtLibrary.RubyTimestamp.newRubyTimestamp(
                RubyUtil.RUBY, new Timestamp((DateTime) input)
            )
        );
        converters.put(RubyHash.class, input -> ConvertedMap.newFromRubyHash((RubyHash) input));
        converters.put(Map.class, input -> ConvertedMap.newFromMap((Map<String, Object>) input));
        converters.put(List.class, input -> ConvertedList.newFromList((List) input));
        converters.put(ArrayJavaProxy.class, JAVAPROXY_CONVERTER);
        converters.put(ConcreteJavaProxy.class, JAVAPROXY_CONVERTER);
        converters.put(
            MapJavaProxy.class,
            input -> ConvertedMap.newFromMap(
                (Map<String, Object>) ((MapJavaProxy) input).getObject()
            )
        );
        converters.put(
            RubyArray.class, input -> ConvertedList.newFromRubyArray((RubyArray) input)
        );
        return converters;
    }

    public interface Converter {

        Object convert(Object input);
    }
}
