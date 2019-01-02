package org.logstash;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;

import java.util.concurrent.ConcurrentHashMap;
import org.jruby.RubyString;

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

    private static final Logger LOGGER = LogManager.getLogger(FieldReference.class);

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
     * Controls the global parsing mode, in support of the transition to strict-mode parsing.
     *
     * See {@link FieldReference#setParsingMode(ParsingMode)}.
     */
    private static ParsingMode PARSING_MODE = ParsingMode.LEGACY;

    /**
     * The {@link ParsingMode} enum holds references to the supported parsing modes, in
     * support of the transition to strict-mode parsing.
     */
    public enum ParsingMode {
        LEGACY(new LegacyTokenizer()),
        COMPAT(new StrictTokenizer(LEGACY.tokenizer)),
        STRICT(new StrictTokenizer()),
        ;

        final Tokenizer tokenizer;

        ParsingMode(final Tokenizer tokenizer) {
            this.tokenizer = tokenizer;
        }
    }

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
     * Sets the global {@link ParsingMode}
     *
     * @param newParsingMode a {@link ParsingMode} to be used globally
     * @return the previous {@link ParsingMode}, enabling tests to reset to default behaviour
     */
    public static ParsingMode setParsingMode(final ParsingMode newParsingMode) {
        final ParsingMode originalParsingMode = PARSING_MODE;
        PARSING_MODE = newParsingMode;
        return originalParsingMode;
    }

    /**
     * @return the current global {@link ParsingMode}.
     */
    static ParsingMode getParsingMode() {
        return PARSING_MODE;
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
        final List<String> path = PARSING_MODE.tokenizer.tokenize(reference);

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
     * A temporary private interface to support the transition to strict-mode tokenizing.
     */
    private interface Tokenizer {
        List<String> tokenize(final CharSequence reference);
    }

    /**
     * The {@link LegacyTokenizer} is verbatim the tokenizer code that has long been a part
     * of {@link FieldReference#parse(CharSequence)}.
     *
     * While it handles fully-legal bracket-style and no-bracket inputs, it behaves in
     * surprising ways when given illegal-syntax inputs.
     */
    private static class LegacyTokenizer implements Tokenizer {
        @Override
        public List<String> tokenize(CharSequence reference) {
            final ArrayList<String> path = new ArrayList<>();
            final int length = reference.length();
            int splitPoint = 0;
            for (int i = 0; i < length; ++i) {
                final char seen = reference.charAt(i);
                if (seen == '[' || seen == ']') {
                    if (i == 0) {
                        splitPoint = 1;
                    }
                    if (i > splitPoint) {
                        path.add(reference.subSequence(splitPoint, i).toString().intern());
                    }
                    splitPoint = i + 1;
                }
            }
            if (splitPoint < length || length == 0) {
                path.add(reference.subSequence(splitPoint, length).toString().intern());
            }
            if (path.isEmpty()) {
                // https://github.com/elastic/logstash/issues/9524
                // prevents an ArrayIndexOutOfBounds exception that would crash the entire Logstash process.
                // If the path is empty, we have an illegal syntax input and are unable to build a valid
                // FieldReference; throw a runtime exception, which can be handled downstream.
                throw new IllegalSyntaxException(String.format("Invalid FieldReference: `%s`", reference.toString()));
            }
            path.trimToSize();

            return path;
        }
    }

    /**
     * The {@link StrictTokenizer} parses field-references in a strict manner; when illegal syntax is encountered,
     * the input is considered ambiguous.
     *
     * If instantiated with a fallback {@link Tokenizer}, when it encounters ambiguous input it will always return
     * an output that is identical to the output of the fallback {@link Tokenizer#tokenize(CharSequence)}; when their
     * outputs would differ, it also emits a warning to the logger for each distinct illegal input it encounters.
     */
    private static class StrictTokenizer implements Tokenizer {
        private static final Set<CharSequence> AMBIGUOUS_INPUTS = new HashSet<>();

        final Tokenizer legacyTokenizer;

        StrictTokenizer(final Tokenizer legacyTokenizer) {
            this.legacyTokenizer = Objects.requireNonNull(legacyTokenizer,
                                                          "to run strict without a fallbackTokenizer, " +
                                                          "use zero-arg variant");
        }

        StrictTokenizer() {
            this.legacyTokenizer = null;
        }

        @Override
        public List<String> tokenize(CharSequence reference) {
            ArrayList<String> path = new ArrayList<>();
            final int length = reference.length();

            boolean strictMode = !Objects.nonNull(legacyTokenizer);

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
                if (strictMode) {
                    throw new FieldReference.IllegalSyntaxException(String.format("Invalid FieldReference: `%s`", reference.toString()));
                } else {
                    final List<String> legacyPath = legacyTokenizer.tokenize(reference);
                    if (!path.equals(legacyPath)) {
                        warnAmbiguous(reference, legacyPath);
                    }
                    return legacyPath;
                }
            }

            path.trimToSize();
            return path;
        }

        private void warnAmbiguous(final CharSequence reference, final List<String> expansion) {
            if (AMBIGUOUS_INPUTS.size() > 10_000) {
                return;
            }
            if (AMBIGUOUS_INPUTS.add(reference)) {
                // TODO: i18n
                LOGGER.warn(String.format("Detected ambiguous Field Reference `%s`, which we expanded to the path `%s`; in a future release of Logstash, ambiguous Field References will not be expanded.", reference.toString(), expansion));
            }
        }
    }
}
