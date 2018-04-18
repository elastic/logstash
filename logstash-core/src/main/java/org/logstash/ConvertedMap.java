package org.logstash;

import java.io.Serializable;
import java.util.HashMap;
import java.util.IdentityHashMap;
import java.util.Map;
import org.jruby.RubyHash;
import org.jruby.RubyString;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.execution.WorkerLoop;

/**
 * <p>This class is an internal API and behaves very different from a standard {@link Map}.</p>
 * <p>The {@code get} method only has defined behaviour when used with an interned {@link String}
 * as key.</p>
 * <p>The {@code put} method will work with any {@link String} key but is only intended for use in
 * situations where {@link ConvertedMap#putInterned(String, Object)} would require manually
 * interning the {@link String} key. This is due to the fact that we use our internal
 * {@link FieldReference} cache to get an interned version of the given key instead of JDKs
 * {@link String#intern()}, which is faster since it works from a much smaller and hotter cache
 * in {@link FieldReference#CACHE} than using String interning directly.</p>
 */
public final class ConvertedMap extends IdentityHashMap<String, Object> {

    private static final long serialVersionUID = 1L;

    private static final RubyHash.VisitorWithState<ConvertedMap> RUBY_HASH_VISITOR =
        new RubyHash.VisitorWithState<ConvertedMap>() {
            @Override
            public void visit(final ThreadContext context, final RubyHash self,
                final IRubyObject key, final IRubyObject value,
                final int index, final ConvertedMap state) {
                if (key instanceof RubyString) {
                    state.putInterned(convertKey((RubyString) key), Valuefier.convert(value));
                } else {
                    state.put(key.toString(), Valuefier.convert(value));
                }
            }
        };

    ConvertedMap() {
        super(10);
    }

    ConvertedMap(final int size) {
        super(size);
    }

    public static ConvertedMap newFromMap(Map<? extends Serializable, Object> o) {
        ConvertedMap cm = new ConvertedMap(o.size());
        for (final Map.Entry<? extends Serializable, Object> entry : o.entrySet()) {
            final Serializable found = entry.getKey();
            if (found instanceof String) {
                cm.put((String) found, Valuefier.convert(entry.getValue()));
            } else {
                cm.putInterned(convertKey((RubyString) found), entry.getValue());
            }
        }
        return cm;
    }

    public static ConvertedMap newFromRubyHash(final RubyHash o) {
        return newFromRubyHash(WorkerLoop.THREAD_CONTEXT.get(), o);
    }

    public static ConvertedMap newFromRubyHash(final ThreadContext context, final RubyHash o) {
        final ConvertedMap result = new ConvertedMap(o.size());
        o.visitAll(context, RUBY_HASH_VISITOR, result);
        return result;
    }

    @Override
    public Object put(final String key, final Object value) {
        return super.put(FieldReference.from(key).getKey(), value);
    }

    /**
     * <p>Behaves like a standard {@link Map#put(Object, Object)} but without the return value.</p>
     * <p>Only produces correct results if the given {@code key} is an interned {@link String}.</p>
     * @param key Interned String
     * @param value Value to put
     */
    public void putInterned(final String key, final Object value) {
        super.put(key, value);
    }

    public Object unconvert() {
        final HashMap<String, Object> result = new HashMap<>(size());
        for (final Map.Entry<String, Object> entry : entrySet()) {
            result.put(entry.getKey(), Javafier.deep(entry.getValue()));
        }
        return result;
    }

    /**
     * Converts a {@link RubyString} into a {@link String} that is guaranteed to be interned.
     * @param key RubyString to convert
     * @return Interned String
     */
    private static String convertKey(final RubyString key) {
        return FieldReference.from(key.getByteList()).getKey();
    }
}
