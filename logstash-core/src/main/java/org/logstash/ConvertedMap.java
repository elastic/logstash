package org.logstash;

import java.io.Serializable;
import java.lang.ref.WeakReference;
import java.util.*;
import java.util.concurrent.atomic.AtomicBoolean;

import org.jruby.RubyHash;
import org.jruby.RubyString;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.openjdk.tools.javac.util.Convert;

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
    private final Set<String> cowKeys = new HashSet<>();

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

    ConvertedMap(ConvertedMap cowParent) {
        super(cowParent.size());
    }

    /**
     * Creates a shallow copy of an Event
     * @return
     */
    public ConvertedMap cowCopy() {
        ConvertedMap copy = new ConvertedMap(this);
        for (final Map.Entry<String, Object> entry : this.entrySet()) {
            this.cowKeys.add(entry.getKey());
            copy.cowKeys.add(entry.getKey());
            copy.putInternedCowUnsafe(entry.getKey(), entry.getValue());
        }
        return copy;
    }

    // Only for internal use, doesn't uncow things.
    private void putInternedCowUnsafe(String key, Object value) {
        super.put(key, value);
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
        return newFromRubyHash(o.getRuntime().getCurrentContext(), o);
    }

    public static ConvertedMap newFromRubyHash(final ThreadContext context, final RubyHash o) {
        final ConvertedMap result = new ConvertedMap(o.size());
        o.visitAll(context, RUBY_HASH_VISITOR, result);
        return result;
    }

    @Override
    public Object put(final String key, final Object value) {
        final FieldReference fr = FieldReference.from(key);
        cowKeys.remove(fr.getKey());
        return super.put(fr.getKey(), value);
    }

    /**
     * <p>Behaves like a standard {@link Map#put(Object, Object)} but without the return value.</p>
     * <p>Only produces correct results if the given {@code key} is an interned {@link String}.</p>
     * @param key Interned String
     * @param value Value to put
     */
    public void putInterned(final String key, final Object value) {
        cowKeys.remove(key);
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

    public void deCow(FieldReference field) {
        String root = field.getRoot();
        boolean removed = cowKeys.remove(root);
        if (removed) {
            FieldReference rootFieldRef = FieldReference.from(field.getRoot());
            Object original = get(rootFieldRef.getKey());
            Object clone = Cloner.deep(original);
            if (clone instanceof Map && !(clone instanceof ConvertedMap)) {
                clone = ConvertedMap.newFromMap((Map) clone);
            }
            putInternedCowUnsafe(rootFieldRef.getKey(), clone);
        }
    }
}
