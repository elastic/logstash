package org.logstash;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import java.util.concurrent.ConcurrentHashMap;
import org.jruby.RubyString;

public final class FieldReference {
    /**
     * A custom unchecked {@link RuntimeException} that can be thrown by parsing methods when
     * when they encounter an input with illegal syntax.
     */
    public static class IllegalSyntaxException extends RuntimeException {
        IllegalSyntaxException(String message) {
            super(message);
        }
    }

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

    /**
     * Holds all existing {@link FieldReference} instances for de-duplication.
     */
    private static final Map<FieldReference, FieldReference> DEDUP = new HashMap<>(64);

    /**
     * The tokenizer that will be used when parsing field references
     */
    private static final StrictTokenizer TOKENIZER = new StrictTokenizer();

    /**
     * Unique {@link FieldReference} pointing at the timestamp field in a {@link Event}.
     */
    public static final FieldReference TIMESTAMP_REFERENCE =
        deduplicate(new FieldReference(EMPTY_STRING_ARRAY, Event.TIMESTAMP, DATA_CHILD));

    private static final FieldReference METADATA_PARENT_REFERENCE =
        new FieldReference(EMPTY_STRING_ARRAY, Event.METADATA, META_PARENT);

    /**
     * Cache of all existing {@link FieldReference} by their {@link RubyString} source.
     */
    private static final Map<RubyString, FieldReference> RUBY_CACHE =
        new ConcurrentHashMap<>(64, 0.2F, 1);

    /**
     * Cache of all existing {@link FieldReference} by their {@link String} source.
     */
    private static final Map<String, FieldReference> CACHE =
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

    public static FieldReference from(final RubyString reference) {
        // atomicity between the get and put is not important
        final FieldReference result = RUBY_CACHE.get(reference);
        if (result != null) {
            return result;
        }
        return RUBY_CACHE.computeIfAbsent(reference.newFrozen(), ref -> from(ref.asJavaString()));
    }

    public static FieldReference from(final String reference) {
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

    private static FieldReference parseToCache(final String reference) {
        FieldReference result = parse(reference);
        if (CACHE.size() < 10_000) {
            result = deduplicate(result);
            CACHE.put(reference, result);
        }
        return result;
    }

    private static FieldReference parse(final CharSequence reference) {
        final List<String> path = TOKENIZER.tokenize(reference);

        final String key = path.remove(path.size() - 1).intern();
        final boolean empty = path.isEmpty();
        if (empty && key.equals(Event.METADATA)) {
            return METADATA_PARENT_REFERENCE;
        } else if (!empty && path.get(0).equals(Event.METADATA)) {
            return new FieldReference(
                path.subList(1, path.size()).toArray(EMPTY_STRING_ARRAY), key, META_CHILD
            );
        } else {
            return new FieldReference(path.toArray(EMPTY_STRING_ARRAY), key, DATA_CHILD);
        }
    }

    /**
     * The {@link StrictTokenizer} parses field-references in a strict manner; when illegal syntax is encountered,
     * the input is considered ambiguous and the reference is not expanded.
     **/
    private static class StrictTokenizer {

        public List<String> tokenize(CharSequence reference) {
            ArrayList<String> path = new ArrayList<>();
            final int length = reference.length();

            boolean potentiallyAmbiguousSyntaxDetected = false;
            boolean seenBracket = false;
            int depth = 0;
            int splitPoint = 0;
            char current = 0;
            char previous = 0;
            scan: for (int i=0 ; i < length; i++) {
                previous = current;
                current = reference.charAt(i);
                switch (current) {
                    case '[':
                        seenBracket = true;
                        if (splitPoint != i) {
                            // if the current split point isn't the previous character, we have ambiguous input,
                            // such as a mix of square-bracket and top-level unbracketed chunks, or an embedded
                            // field reference that doesn't wholly occupy an outer fragment, and cannot
                            // reasonably recover.
                            potentiallyAmbiguousSyntaxDetected = true;
                            break scan;
                        }

                        depth++;
                        splitPoint = i + 1;
                        continue scan;

                    case ']':
                        seenBracket = true;
                        if (depth <= 0) {
                            // if we get to a close-bracket without having previously hit an open-bracket,
                            // we have an illegal field reference and cannot reasonably recover.
                            potentiallyAmbiguousSyntaxDetected = true;
                            break scan;
                        }
                        if (splitPoint == i && previous != ']') {
                            // if we have a zero-length fragment and are not closing an embedded fieldreference,
                            // we have an illegal field reference and cannot possibly recover.
                            potentiallyAmbiguousSyntaxDetected = true;
                            break scan;
                        }

                        if (splitPoint < i) {
                            // if we have something to add, add it.
                            path.add(reference.subSequence(splitPoint, i).toString().intern());
                        }

                        depth--;
                        splitPoint = i + 1;
                        continue scan;

                    default:
                        if (seenBracket && previous == ']') {
                            // if we have seen a bracket and encounter one or more characters that are _not_ enclosed
                            // in brackets, we have illegal syntax and cannot reasonably recover.
                            potentiallyAmbiguousSyntaxDetected = true;
                            break scan;
                        }

                        continue scan;
                }
            }

            if (!seenBracket) {
                // if we saw no brackets, this is a top-level reference that can be emitted as-is without
                // further processing
                path.add(reference.toString());
                return path;
            } else if (depth > 0) {
                // when we hit the end-of-input while still in an open bracket, we have an invalid field reference
                potentiallyAmbiguousSyntaxDetected = true;
            }

            // if we have encountered ambiguous syntax and are not in strict-mode,
            // fall back to legacy parser.
            if (potentiallyAmbiguousSyntaxDetected) {
                throw new FieldReference.IllegalSyntaxException(String.format("Invalid FieldReference: `%s`", reference.toString()));
            }

            path.trimToSize();
            return path;
        }
    }
}
