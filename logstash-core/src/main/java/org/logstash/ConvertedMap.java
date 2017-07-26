package org.logstash;

import java.io.Serializable;
import java.util.HashMap;
import java.util.Map;
import org.jruby.RubyHash;
import org.jruby.runtime.builtin.IRubyObject;

public final class ConvertedMap extends HashMap<String, Object> {

    private static final long serialVersionUID = -4651798808586901122L;

    ConvertedMap(final int size) {
        super((size << 2) / 3 + 2);
    }
    
    public static ConvertedMap newFromMap(Map<Serializable, Object> o) {
        ConvertedMap cm = new ConvertedMap(o.size());
        for (final Map.Entry<Serializable, Object> entry : o.entrySet()) {
            cm.put(entry.getKey().toString(), Valuefier.convert(entry.getValue()));
        }
        return cm;
    }

    public static ConvertedMap newFromRubyHash(RubyHash o) {
        final ConvertedMap result = new ConvertedMap(o.size());

        o.visitAll(new RubyHash.Visitor() {
            @Override
            public void visit(IRubyObject key, IRubyObject value) {
                result.put(key.toString(), Valuefier.convert(value));
            }
        });
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
