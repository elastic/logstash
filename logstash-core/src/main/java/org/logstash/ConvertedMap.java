/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *	http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */


package org.logstash;

import java.io.Serializable;
import java.math.BigDecimal;
import java.math.BigInteger;
import java.util.Collection;
import java.util.HashMap;
import java.util.IdentityHashMap;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import org.jruby.RubyBignum;
import org.jruby.RubyBoolean;
import org.jruby.RubyFixnum;
import org.jruby.RubyFloat;
import org.jruby.RubyHash;
import org.jruby.RubyNil;
import org.jruby.RubyString;
import org.jruby.RubySymbol;
import org.jruby.ext.bigdecimal.RubyBigDecimal;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.ext.JrubyTimestampExtLibrary;

/**
 * <p>This class is an internal API and behaves very different from a standard {@link Map}.</p>
 * <p>The {@code get} method only has defined behaviour when used with an interned {@link String}
 * as key.</p>
 * <p>The {@code put} method will work with any {@link String} key but is only intended for use in
 * situations where {@link ConvertedMap#putInterned(String, Object)} would require manually
 * interning the {@link String} key.
 * This is due to the fact that it is based on {@link IdentityHashMap}, and we rely on the String
 * intern pool to ensure identity match of equivalent strings.
 * For performance, we keep a global cache of strings that have been interned for use with {@link ConvertedMap},
 * and encourage interning through {@link ConvertedMap#internStringForUseAsKey(String)} to avoid
 * the performance penalty of the global string intern pool.
 */
public final class ConvertedMap extends IdentityHashMap<String, Object> {

    private static final long serialVersionUID = 1L;

    private static final ConcurrentHashMap<String,String> KEY_CACHE = new ConcurrentHashMap<>(100, 0.2F, 16);

    /**
     * Returns an equivalent interned string, possibly avoiding the
     * global intern pool.
     *
     * @param candidate the candidate {@link String}
     * @return an interned string from the global String intern pool
     */
    static String internStringForUseAsKey(final String candidate) {
        // TODO: replace with LRU cache and/or isolated intern pool
        final String cached = KEY_CACHE.get(candidate);
        if (cached != null) { return cached; }

        final String interned = candidate.intern();
        if (KEY_CACHE.size() <= 10_000 ) {
            KEY_CACHE.put(interned, interned);
        }
        return interned;
    }

    /**
     * Ensures that the provided {@code String[]} contains only
     * instances that have been {@link ConvertedMap::internStringForUseAsKey},
     * possibly replacing entries with equivalent interned strings.
     *
     * @param candidates an array of non-null strings
     */
    static void internStringsForUseAsKeys(final String[] candidates) {
        for (int i = 0; i < candidates.length; i++) {
            candidates[i] = internStringForUseAsKey(candidates[i]);
        }
    }

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
        return newFromRubyHash(RubyUtil.RUBY.getCurrentContext(), o);
    }

    public static ConvertedMap newFromRubyHash(final ThreadContext context, final RubyHash o) {
        final ConvertedMap result = new ConvertedMap(o.size());
        o.visitAll(context, RUBY_HASH_VISITOR, result);
        return result;
    }

    @Override
    public Object put(final String key, final Object value) {
        return super.put(internStringForUseAsKey(key), value);
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
        return internStringForUseAsKey(key.asJavaString());
    }

    public long estimateMemory() {
        return values().stream()
                .map(this::estimateMemory)
                .mapToLong(Long::longValue)
                .sum();
    }

    @SuppressWarnings({"rawtypes", "unchecked"})
    private long estimateMemory(Object o) {
        if (o instanceof Boolean) {
            return Byte.BYTES;
        }
        if (o instanceof Byte) {
            return Byte.BYTES;
        }
        if (o instanceof Short) {
            return Short.BYTES;
        }
        if (o instanceof Integer) {
            return Integer.BYTES;
        }
        if (o instanceof Long) {
            return Long.BYTES;
        }
        if (o instanceof Float) {
            return Float.BYTES;
        }
        if (o instanceof Double) {
            return Double.BYTES;
        }
        if (o instanceof Character) {
            return Character.BYTES;
        }
        if (o instanceof String) {
            return ((String) o).getBytes().length;
        }
        if (o instanceof RubyString) {
            return ((RubyString) o).getBytes().length;
        }

        if (o instanceof Collection) {
            Collection c = (Collection) o;
            long memory = 0L;
            for (Object v : c) {
                memory += estimateMemory(v);
            }
            return memory;
        }

        if (o instanceof ConvertedMap) {
            ConvertedMap c = (ConvertedMap) o;
            return c.estimateMemory();
        }

        if (o instanceof Map) {
            // this case shouldn't happen because all Map are converted to ConvertedMap
            Map<String, Object> m = (Map<String, Object>) o;
            long memory = 0L;
            for (Map.Entry e : m.entrySet()) {
                memory += estimateMemory(e.getKey());
                memory += estimateMemory(e.getValue());
            }
            return memory;
        }
        if (o instanceof JrubyTimestampExtLibrary.RubyTimestamp) {
            // wraps an java.time.Instant which is made of long and int
            return Long.BYTES + Integer.BYTES;
        }
        if (o instanceof BigInteger) {
            return ((BigInteger) o).toByteArray().length;
        }
        if (o instanceof BigDecimal) {
            // BigInteger has 4 fields, one reference 2 ints (scale and precision) and a long.
            return 8 + 2 * Integer.BYTES + Long.BYTES;
        }
        if (o instanceof RubyBignum) {
            RubyBignum rbn = (RubyBignum) o;
            return rbn.getBigIntegerValue().bitLength() / 8 + 1;
        }
        if (o instanceof RubyBigDecimal) {
            RubyBigDecimal rbd = (RubyBigDecimal) o;
            // wraps a Java BigDecimal so we can return the size of that:
            return estimateMemory(rbd.getValue());
        }
        if (o instanceof RubyFixnum) {
            // like an int value
            return Integer.BYTES;
        }
        if (o instanceof RubyBoolean) {
            return Byte.BYTES;
        }
        if (o instanceof RubyNil) {
            return 8 + Integer.BYTES; // object reference, one int
        }
        if (o instanceof RubySymbol) {
            return estimateMemory(((RubySymbol) o).asJavaString());
        }
        if (o instanceof RubyFloat) {
            return Double.BYTES;
        }

        throw new IllegalArgumentException(
                "Unsupported type encountered in estimateMemory: " + o.getClass().getName() +
                        ". Please ensure all objects passed to estimateMemory are of supported types. " +
                        "Refer to the ConvertedMap.estimateMemory method for the list of supported types."
        );
    }
}
