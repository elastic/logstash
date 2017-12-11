package org.logstash;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.regex.Pattern;

public final class FieldReference {

    /**
     * This type indicates that the referenced that is the metadata of an {@link Event} found in
     * {@link Event#metadata}.
     */
    public static final int META_PARENT = 0;

    /**
     * This type indicates that the referenced data must be looked up from {@link Event#metadata}.
     */
    public static final int META_CHILD = 1;

    /**
     * This type indicates that the referenced data must be looked up from {@link Event#data}.
     */
    private static final int DATA_CHILD = -1;

    private static final String[] EMPTY_STRING_ARRAY = new String[0];

    private static final Pattern SPLIT_PATTERN = Pattern.compile("[\\[\\]]");

    /**
     * Holds all existing {@link FieldReference} instances for de-duplication.
     */
    private static final Map<FieldReference, FieldReference> DEDUP = new HashMap<>(64);

    /**
     * Unique {@link FieldReference} pointing at the timestamp field in a {@link Event}.
     */
    public static final FieldReference TIMESTAMP_REFERENCE =
        deduplicate(new FieldReference(EMPTY_STRING_ARRAY, Event.TIMESTAMP, DATA_CHILD));

    private static final FieldReference METADATA_PARENT_REFERENCE =
        new FieldReference(EMPTY_STRING_ARRAY, Event.METADATA, META_PARENT);

    static final FieldReference DATA_EMPTY_STRING_REFERENCE =
            new FieldReference(EMPTY_STRING_ARRAY, "", DATA_CHILD);

    /**
     * Cache of all existing {@link FieldReference}.
     */
    private static final Map<CharSequence, FieldReference> CACHE =
        new ConcurrentHashMap<>(64, 0.2F, 1);

    private final String[] path;

    private final String key;

    private final int hash;

    /**
     * Either {@link FieldReference#META_PARENT}, {@link FieldReference#META_CHILD} or
     * {@link FieldReference#DATA_CHILD}.
     */
    private final int type;

    private FieldReference(final String[] path, final String key, final int type) {
        this.key = key;
        this.type = type;
        this.path = path;
        hash = calculateHash(this.key, this.path, this.type);
    }

    public static FieldReference from(final CharSequence reference) {
        if( reference == null || reference.length() == 0){
            return DATA_EMPTY_STRING_REFERENCE;
        }
        // atomicity between the get and put is not important
        final FieldReference result = CACHE.get(reference);
        if (result != null) {
            return result;
        }
        return parseToCache(reference);
    }

    /**
     * Returns the type of this instance to allow for fast switch operations in
     * {@link Event#getUnconvertedField(FieldReference)} and
     * {@link Event#setField(FieldReference, Object)}.
     * @return Type of the FieldReference
     */
    public int type() {
        return type;
    }

    public String[] getPath() {
        return path;
    }

    public String getKey() {
        return key;
    }

    @Override
    public boolean equals(final Object that) {
        if (this == that) return true;
        if (!(that instanceof FieldReference)) return false;
        final FieldReference other = (FieldReference) that;
        return type == other.type && key.equals(other.key) && Arrays.equals(path, other.path);
    }

    @Override
    public int hashCode() {
        return hash;
    }

    /**
     * De-duplicates instances using {@link FieldReference#DEDUP}. This method must be
     * {@code synchronized} since we are running non-atomic get-put sequence on
     * {@link FieldReference#DEDUP}.
     * @param parsed FieldReference to de-duplicate
     * @return De-duplicated FieldReference
     */
    private static synchronized FieldReference deduplicate(final FieldReference parsed) {
        FieldReference ret = DEDUP.get(parsed);
        if (ret == null) {
            DEDUP.put(parsed, parsed);
            ret = parsed;
        }
        return ret;
    }

    /**
     * Effective hashcode implementation using knowledge of field types.
     * @param key Key Field
     * @param path Path Field
     * @param type Type Field
     * @return Hash Code
     */
    private static int calculateHash(final String key, final String[] path, final int type) {
        final int prime = 31;
        int hash = prime;
        for (final String element : path) {
            hash = prime * hash + element.hashCode();
        }
        hash = prime * hash + key.hashCode();
        return prime * hash + type;
    }

    private static FieldReference parseToCache(final CharSequence reference) {
        final FieldReference result = parse(reference);
        CACHE.put(reference, result);
        return result;
    }

    private static FieldReference parse(final CharSequence reference) {
        final String[] parts = SPLIT_PATTERN.split(reference);
        final List<String> path = new ArrayList<>(parts.length);
        for (final String part : parts) {
            if (!part.isEmpty()) {
                path.add(part.intern());
            }
        }
        final String key = path.remove(path.size() - 1).intern();
        final boolean empty = path.isEmpty();
        if (empty && key.equals(Event.METADATA)) {
            return METADATA_PARENT_REFERENCE;
        } else if (!empty && path.get(0).equals(Event.METADATA)) {
            return deduplicate(new FieldReference(
                path.subList(1, path.size()).toArray(EMPTY_STRING_ARRAY), key, META_CHILD));
        } else {
            return deduplicate(
                new FieldReference(path.toArray(EMPTY_STRING_ARRAY), key, DATA_CHILD));
        }
    }
}
