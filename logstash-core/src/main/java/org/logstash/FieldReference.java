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

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import com.google.common.cache.CacheBuilder;
import com.google.common.cache.CacheLoader;
import com.google.common.cache.LoadingCache;
import org.jruby.RubyString;

/**
 * Represents a reference to another field of the event {@link Event}
 * */
public final class FieldReference {
    /**
     * A custom unchecked {@link RuntimeException} that can be thrown by parsing methods when
     * when they encounter an input with illegal syntax.
     */
    public static class IllegalSyntaxException extends RuntimeException {
        private static final long serialVersionUID = 1L;
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
     * The tokenizer that will be used when parsing field references
     */
    private static final StrictTokenizer TOKENIZER = new StrictTokenizer();

    /**
     * Unique {@link FieldReference} pointing at the timestamp field in a {@link Event}.
     */
    public static final FieldReference TIMESTAMP_REFERENCE =
            new FieldReference(EMPTY_STRING_ARRAY, Event.TIMESTAMP, DATA_CHILD);

    private static final FieldReference METADATA_PARENT_REFERENCE =
        new FieldReference(EMPTY_STRING_ARRAY, Event.METADATA, META_PARENT);

    private static final int CACHE_MAXIMUM_SIZE = 10_000;

    /**
     * Cache of all existing {@link FieldReference} by their {@link RubyString} source.
     */
    private static final LoadingCache<RubyString, FieldReference> RUBY_CACHE = CacheBuilder.newBuilder()
            .maximumSize(CACHE_MAXIMUM_SIZE)
            .build(new CacheLoader<RubyString, FieldReference>() {
                public FieldReference load(RubyString key) {
                    return parse(key);
                }
            });

    /**
     * Cache of all existing {@link FieldReference} by their {@link String} source.
     */
    private static final LoadingCache<String, FieldReference> CACHE = CacheBuilder.newBuilder()
            .maximumSize(CACHE_MAXIMUM_SIZE)
            .build(new CacheLoader<String, FieldReference>() {
                public FieldReference load(String key) {
                    return parse(key);
                }
            });

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
        FieldReference result = RUBY_CACHE.getIfPresent(reference);
        if (result == null) {
            result = RUBY_CACHE.getUnchecked(reference.newFrozen());
        }
        return result;
    }

    public static FieldReference from(final String reference) throws IllegalSyntaxException {
        return CACHE.getUnchecked(reference);
    }

    public static boolean isValid(final String reference) {
        try {
            FieldReference.from(reference);
            return true;
        } catch (IllegalSyntaxException ise) {
            return false;
        }
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

    private static FieldReference parse(final CharSequence reference) {
        final List<String> path = TOKENIZER.tokenize(reference);

        final String key = path.remove(path.size() - 1);
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
