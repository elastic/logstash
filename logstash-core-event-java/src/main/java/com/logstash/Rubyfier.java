package com.logstash;

import com.logstash.ext.JrubyTimestampExtLibrary;
import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyHash;
import org.jruby.ext.bigdecimal.RubyBigDecimal;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.builtin.IRubyObject;

import java.math.BigDecimal;
import java.util.*;

public final class Rubyfier {

    private Rubyfier(){}

    public static IRubyObject deep(Ruby runtime, final Object input) {
        if (input instanceof IRubyObject) return (IRubyObject)input;
        if (input instanceof Map) return deepMap(runtime, (Map) input);
        if (input instanceof List) return deepList(runtime, (List) input);
        if (input instanceof Timestamp) return JrubyTimestampExtLibrary.RubyTimestamp.newRubyTimestamp(runtime, (Timestamp)input);
        if (input instanceof Collection) throw new ClassCastException("unexpected Collection type " + input.getClass());

        // BigDecimal is not currenly handled by JRuby and this is the type Jackson uses for floats
        if (input instanceof BigDecimal) return new RubyBigDecimal(runtime, runtime.getClass("BigDecimal"), (BigDecimal)input);

        return JavaUtil.convertJavaToUsableRubyObject(runtime, input);
    }

    public static Object deepOnly(Ruby runtime, final Object input) {
        if (input instanceof Map) return deepMap(runtime, (Map) input);
        if (input instanceof List) return deepList(runtime, (List) input);
        if (input instanceof Timestamp) return JrubyTimestampExtLibrary.RubyTimestamp.newRubyTimestamp(runtime, (Timestamp)input);
        if (input instanceof Collection) throw new ClassCastException("unexpected Collection type " + input.getClass());

        // BigDecimal is not currenly handled by JRuby and this is the type Jackson uses for floats
        if (input instanceof BigDecimal) return new RubyBigDecimal(runtime, runtime.getClass("BigDecimal"), (BigDecimal)input);

        return input;
    }

    private static RubyArray deepList(Ruby runtime, final List list) {
        final int length = list.size();
        final RubyArray array = runtime.newArray(length);

        for (Object item : list) {
            // use deepOnly because RubyArray.add already calls JavaUtil.convertJavaToUsableRubyObject on item
            array.add(deepOnly(runtime, item));
        }

        return array;
    }

    private static RubyHash deepMap(Ruby runtime, final Map<?, ?> map) {
        RubyHash hash = RubyHash.newHash(runtime);

        for (Map.Entry<?, ?> entry : map.entrySet()) {
            // use deepOnly on value because RubyHash.put already calls JavaUtil.convertJavaToUsableRubyObject on items
            hash.put(entry.getKey(), deepOnly(runtime, entry.getValue()));
        }

        return hash;
    }
}
