package org.logstash;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import org.jruby.RubyBoolean;
import org.jruby.RubyFixnum;
import org.jruby.RubyFloat;
import org.jruby.RubyString;
import org.logstash.bivalues.BiValue;
import org.logstash.bivalues.BiValues;
import org.logstash.ext.JrubyTimestampExtLibrary;

public final class Javafier {

    private static final Map<Class<?>, Valuefier.Converter> CONVERTER_MAP = initConverters();

    private static final Valuefier.Converter BIVALUES_CONVERTER =
        value -> BiValues.newBiValue(value).javaValue();

    /**
     * Javafier.deep() is called by getField.
     * When any value is added to the Event it should pass through Valuefier.convert.
     * deep(Object o) is the mechanism to pluck the Java value from a BiValue or convert a
     * ConvertedList and ConvertedMap back to ArrayList or HashMap.
     */
    private Javafier() {
    }

    public static Object deep(Object o) {
        final Class<?> cls = o.getClass();
        final Valuefier.Converter converter = CONVERTER_MAP.get(cls);
        if (converter != null) {
            return converter.convert(o);
        }
        return fallbackConvert(o, cls);
    }

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
        converters.put(String.class, Valuefier.IDENTITY);
        converters.put(Float.class, Valuefier.IDENTITY);
        converters.put(Double.class, Valuefier.IDENTITY);
        converters.put(Long.class, Valuefier.IDENTITY);
        converters.put(Integer.class, Valuefier.IDENTITY);
        converters.put(Boolean.class, Valuefier.IDENTITY);
        converters.put(Timestamp.class, Valuefier.IDENTITY);
        // Explicitly casting to RubyString when we know it's a RubyString for sure is faster
        // than having the JVM look up the type.
        converters.put(RubyString.class, value -> ((RubyString) value).toString());
        converters.put(RubyBoolean.class, value -> ((RubyBoolean) value).isTrue());
        converters.put(BiValue.class, value -> ((BiValue<?, ?>) value).javaValue());
        converters.put(RubyFixnum.class, value -> ((RubyFixnum) value).getLongValue());
        converters.put(RubyFloat.class, value -> ((RubyFloat) value).getDoubleValue());
        converters.put(ConvertedMap.class, value -> ((ConvertedMap) value).unconvert());
        converters.put(ConvertedList.class, value -> ((ConvertedList) value).unconvert());
        converters.put(
            JrubyTimestampExtLibrary.RubyTimestamp.class,
            value -> ((JrubyTimestampExtLibrary.RubyTimestamp) value).getTimestamp()
        );
        return converters;
    }
}

