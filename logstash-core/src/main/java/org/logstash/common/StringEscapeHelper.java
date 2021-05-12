package org.logstash.common;

import java.util.EnumSet;

public class StringEscapeHelper {

    public enum Feature {
        LEGACY,
    }

    private static final char LITERAL_BACKSLASH = '\\';
    private static final char LITERAL_QUOTE_SINGLE = '\'';
    private static final char LITERAL_QUOTE_DOUBLE = '"';
    private static final char LITERAL_LOWER_N = 'n';
    private static final char LITERAL_LOWER_R = 'r';
    private static final char LITERAL_LOWER_T = 't';
    private static final char LITERAL_NEWLINE = '\n';
    private static final char LITERAL_RETURN = '\r';
    private static final char LITERAL_TAB = '\t';

    private final EnumSet<Feature> activeFeatures;

    public static final StringEscapeHelper DISABLED = new StringEscapeHelper(EnumSet.noneOf(Feature.class));
    public static final StringEscapeHelper MINIMAL = new StringEscapeHelper(EnumSet.of(Feature.LEGACY));

    public static StringEscapeHelper forMode(final String mode) {
        switch(mode) {
            case "disabled": return DISABLED;
            case "minimal":  return MINIMAL;
            default: throw new IllegalArgumentException(String.format("Unsupported string escape mode `%s`", mode));
        }
    }

    private StringEscapeHelper(final EnumSet<Feature> features) {
        activeFeatures = features;
    }

    public String unescape(final String escaped) {
        if (activeFeatures.isEmpty()) { return escaped; }

        final int escapedLength = escaped.length();
        final StringBuilder unescaped = new StringBuilder(escapedLength);

        for(int i = 0; i < escapedLength; i++) {
            final char c = escaped.charAt(i);
            if (c != LITERAL_BACKSLASH) {
                unescaped.append(c);
                continue;
            }

            i++; // consume the escaping backslash
            if (i >= escapedLength) {
                // Last char was an unescaped backslash, which is not technically legal.
                // Emit the literal backslash
                unescaped.append(LITERAL_BACKSLASH);
                break;
            }
            final char seq = escaped.charAt(i);

            switch (seq) {
                // BACKSLASH-ESCAPED LITERALS
                case LITERAL_BACKSLASH:
                case LITERAL_QUOTE_SINGLE:
                case LITERAL_QUOTE_DOUBLE:
                    unescaped.append(seq);
                    continue;

                // BACKSLASH SHORTHAND EXPANSION
                case LITERAL_LOWER_N:
                    unescaped.append(LITERAL_NEWLINE);
                    continue;
                case LITERAL_LOWER_R:
                    unescaped.append(LITERAL_RETURN);
                    continue;
                case LITERAL_LOWER_T:
                    unescaped.append(LITERAL_TAB);
                    continue;

            }

            // Any character following a backslash that does _not_ fit
            // into one of the above will be emitted as-is.
            unescaped.append(seq);
        }

        return unescaped.toString();
    }
}
