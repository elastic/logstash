package org.logstash;

import java.util.Collection;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyBoolean;
import org.jruby.RubyFixnum;
import org.jruby.RubyFloat;
import org.jruby.RubyHash;
import org.jruby.RubyString;
import org.jruby.RubySymbol;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.bivalues.BiValue;
import org.logstash.bivalues.BiValues;
import org.logstash.ext.JrubyTimestampExtLibrary;

public final class Rubyfier {

    private static final Rubyfier.Converter BIVALUES_CONVERTER =
        (ruby, val) -> BiValues.newBiValue(val).rubyValue(ruby);

    private static final Rubyfier.Converter IDENTITY = (runtime, input) -> (IRubyObject) input;

    private static final Rubyfier.Converter FLOAT_CONVERTER =
        (runtime, input) -> runtime.newFloat(((Number) input).doubleValue());

    private static final Rubyfier.Converter LONG_CONVERTER =
        (runtime, input) -> runtime.newFixnum(((Number) input).longValue());

    private static final Map<Class<?>, Rubyfier.Converter> CONVERTER_MAP = initConverters();

    /**
     * Rubyfier.deep() is called by JrubyEventExtLibrary RubyEvent ruby_get_field,
     * ruby_remove, ruby_to_hash and ruby_to_hash_with_metadata.
     * When any value is added to the Event it should pass through Valuefier.convert.
     * Rubyfier.deep is the mechanism to pluck the Ruby value from a BiValue or convert a
     * ConvertedList and ConvertedMap back to RubyArray or RubyHash.
     * However, IRubyObjects and the RUby runtime do not belong in ConvertedMap or ConvertedList
     * so they are unconverted here.
     */
    private Rubyfier() {
    }

    public static IRubyObject deep(final Ruby runtime, final Object input) {
        if (input == null) {
            return runtime.getNil();
        }
        final Class<?> cls = input.getClass();
        final Rubyfier.Converter converter = CONVERTER_MAP.get(cls);
        if (converter != null) {
            return converter.convert(runtime, input);
        }
        return fallbackConvert(runtime, input, cls);
    }

    private static RubyArray deepList(final Ruby runtime, final Collection<?> list) {
        final int length = list.size();
        final RubyArray array = runtime.newArray(length);
        for (final Object item : list) {
            array.add(deep(runtime, item));
        }
        return array;
    }

    private static RubyHash deepMap(final Ruby runtime, final Map<?, ?> map) {
        final RubyHash hash = RubyHash.newHash(runtime);
        // Note: RubyHash.put calls JavaUtil.convertJavaToUsableRubyObject on keys and values
        map.forEach((key, value) -> hash.put(key, deep(runtime, value)));
        return hash;
    }

    private static Map<Class<?>, Rubyfier.Converter> initConverters() {
        final Map<Class<?>, Rubyfier.Converter> converters =
            new ConcurrentHashMap<>(50, 0.2F, 1);
        converters.put(RubyString.class, IDENTITY);
        converters.put(RubySymbol.class, IDENTITY);
        converters.put(RubyFloat.class, IDENTITY);
        converters.put(RubyFixnum.class, IDENTITY);
        converters.put(RubyBoolean.class, IDENTITY);
        converters.put(JrubyTimestampExtLibrary.RubyTimestamp.class, IDENTITY);
        converters.put(String.class, (runtime, input) -> runtime.newString((String) input));
        converters.put(Double.class, FLOAT_CONVERTER);
        converters.put(Float.class, FLOAT_CONVERTER);
        converters.put(Integer.class, LONG_CONVERTER);
        converters.put(Long.class, LONG_CONVERTER);
        converters.put(Boolean.class, (runtime, input) -> runtime.newBoolean((Boolean) input));
        converters.put(
            BiValue.class, (runtime, input) -> ((BiValue<?, ?>) input).rubyValue(runtime)
        );
        converters.put(Map.class, (runtime, input) -> deepMap(runtime, (Map<?, ?>) input));
        converters.put(
            Collection.class, (runtime, input) -> deepList(runtime, (Collection<?>) input)
        );
        converters.put(
            Timestamp.class,
            (runtime, input) -> JrubyTimestampExtLibrary.RubyTimestamp.newRubyTimestamp(
                runtime, (Timestamp) input
            )
        );
        return converters;
    }

    /**
     * Same principle as {@link Valuefier#fallbackConvert(Object, Class)}.
     */
    private static IRubyObject fallbackConvert(final Ruby runtime, final Object o,
        final Class<?> cls) {
        for (final Map.Entry<Class<?>, Rubyfier.Converter> entry : CONVERTER_MAP.entrySet()) {
            if (entry.getKey().isAssignableFrom(cls)) {
                final Rubyfier.Converter found = entry.getValue();
                CONVERTER_MAP.put(cls, found);
                return found.convert(runtime, o);
            }
        }
        CONVERTER_MAP.put(cls, BIVALUES_CONVERTER);
        return BIVALUES_CONVERTER.convert(runtime, o);
    }

    private interface Converter {

        IRubyObject convert(Ruby runtime, Object input);
    }
}
