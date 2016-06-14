package com.logstash;

import com.logstash.bivalues.BiValue;
import com.logstash.bivalues.BiValues;
import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyHash;
import org.jruby.runtime.builtin.IRubyObject;

import java.util.Collection;
import java.util.List;
import java.util.Map;


public final class Rubyfier {

    private Rubyfier() {
    }

    public static IRubyObject deep(Ruby runtime, final Object input) {
        if (input instanceof BiValue) return ((BiValue) input).rubyValue(runtime);
        if (input instanceof IRubyObject) return (IRubyObject) input;
        if (input instanceof Map) return deepMap(runtime, (Map) input);
        if (input instanceof List) return deepList(runtime, (List) input);
        if (input instanceof Collection) throw new ClassCastException("Unexpected Collection type " + input.getClass());

        try {
            return BiValues.newBiValue(input).rubyValue(runtime);
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("Missing Java class handling for full class name=" + input.getClass().getName() + ", simple name=" + input.getClass().getSimpleName());
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

        for (Map.Entry<?, ?> entry : map.entrySet()) {
            hash.put(entry.getKey(), deep(runtime, entry.getValue()));
        }

        return hash;
    }
}
