package org.logstash;

import java.io.Serializable;
import java.util.HashMap;
import java.util.Map;
import org.jruby.RubyHash;
import org.jruby.runtime.builtin.IRubyObject;

public final class ConvertedMap extends HashMap<String, Object> {

    ConvertedMap(final int size) {
        super((size << 2) / 3 + 2);
    }
    
    public static ConvertedMap newFromMap(Map<? extends Serializable, Object> o) {
        ConvertedMap cm = new ConvertedMap(o.size());
        for (final Map.Entry<? extends Serializable, Object> entry : o.entrySet()) {
            cm.put(entry.getKey().toString(), Valuefier.convert(entry.getValue()));
        }
        return cm;
    }

    public static ConvertedMap newFromRubyHash(RubyHash o) {
        final ConvertedMap result = new ConvertedMap(o.size());

        o.visitAll(o.getRuntime().getCurrentContext(), new RubyHash.Visitor() {
            @Override
            public void visit(IRubyObject key, IRubyObject value) {
                result.put(key.toString(), Valuefier.convert(value));
            }
        }, null);
        return result;
    }

    public Object unconvert() {
        final HashMap<String, Object> result = new HashMap<>(size());
        for (final Map.Entry<String, Object> entry : entrySet()) {
            result.put(entry.getKey(), Javafier.deep(entry.getValue()));
        }
        return result;
    }
}
