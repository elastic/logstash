package org.logstash;

import org.logstash.bivalues.BiValue;
import org.logstash.bivalues.BiValues;
import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyHash;
import org.jruby.runtime.builtin.IRubyObject;

import java.util.Collection;
import java.util.List;
import java.util.Map;

public final class Rubyfier {
    private static final String ERR_TEMPLATE = "Missing Java class handling for full class name=%s, simple name=%s";
    /*
    Rubyfier.deep() is called by JrubyEventExtLibrary RubyEvent ruby_get_field,
    ruby_remove, ruby_to_hash and ruby_to_hash_with_metadata.
    When any value is added to the Event it should pass through Valuefier.convert.
    Rubyfier.deep is the mechanism to pluck the Ruby value from a BiValue or convert a
    ConvertedList and ConvertedMap back to RubyArray or RubyHash.
    However, IRubyObjects and the RUby runtime do not belong in ConvertedMap or ConvertedList
    so they are unconverted here.
    */
    private Rubyfier() {
    }

    public static IRubyObject deep(Ruby runtime, final Object input) {
        if (input instanceof BiValue) return ((BiValue) input).rubyValue(runtime);
        if (input instanceof Map) return deepMap(runtime, (Map) input);
        if (input instanceof List) return deepList(runtime, (List) input);
        if (input instanceof Collection) throw new ClassCastException("Unexpected Collection type " + input.getClass());

        try {
            return BiValues.newBiValue(input).rubyValue(runtime);
        } catch (IllegalArgumentException e) {
            Class cls = input.getClass();
            throw new IllegalArgumentException(String.format(ERR_TEMPLATE, cls.getName(), cls.getSimpleName()));
        }
    }

    private static RubyArray deepList(Ruby runtime, final List list) {
        final int length = list.size();
        final RubyArray array = runtime.newArray(length);
        for (Object item : list) {
            array.add(deep(runtime, item));
        }
        return array;
    }

    private static RubyHash deepMap(Ruby runtime, final Map<?, ?> map) {
        RubyHash hash = RubyHash.newHash(runtime);
        for (Map.Entry entry : map.entrySet()) {
            // Note: RubyHash.put calls JavaUtil.convertJavaToUsableRubyObject on keys and values
            hash.put(entry.getKey(), deep(runtime, entry.getValue()));
        }
        return hash;
    }
}
