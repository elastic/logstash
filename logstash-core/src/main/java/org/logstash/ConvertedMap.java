package org.logstash;

import java.io.Serializable;
import java.util.HashMap;
import java.util.Map;
import org.jruby.RubyHash;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

public final class ConvertedMap extends HashMap<String, Object> {

    private static final long serialVersionUID = -4651798808586901122L;

    private static final RubyHash.VisitorWithState<ConvertedMap> RUBY_HASH_VISITOR =
        new RubyHash.VisitorWithState<ConvertedMap>() {
            @Override
            public void visit(final ThreadContext context, final RubyHash self,
                final IRubyObject key, final IRubyObject value,
                final int index, final ConvertedMap state) {
                state.put(key.toString(), Valuefier.convert(value));
            }
        };

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

    public static ConvertedMap newFromRubyHash(final RubyHash o) {
        return newFromRubyHash(o.getRuntime().getCurrentContext(), o);
    }

    public static ConvertedMap newFromRubyHash(final ThreadContext context, final RubyHash o) {
        final ConvertedMap result = new ConvertedMap(o.size());
        o.visitAll(context, RUBY_HASH_VISITOR, result);
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
