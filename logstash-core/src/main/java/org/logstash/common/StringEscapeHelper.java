package org.logstash.common;

import java.util.EnumSet;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class StringEscapeHelper {

    public enum Feature {
        LEGACY,
        ZERO_NULL,
        LOWER_X_CODEPOINT,
        LOWER_U_CODEPOINT,
    }

    private static final char LITERAL_BACKSLASH = '\\';
    private static final char LITERAL_QUOTE_SINGLE = '\'';
    private static final char LITERAL_QUOTE_DOUBLE = '"';
    private static final char LITERAL_LOWER_N = 'n';
    private static final char LITERAL_LOWER_R = 'r';
    private static final char LITERAL_LOWER_T = 't';
    private static final char LITERAL_LOWER_U = 'u';
    private static final char LITERAL_LOWER_X = 'x';
    private static final char LITERAL_ZERO = '0';
    private static final char LITERAL_NEWLINE = '\n';
    private static final char LITERAL_RETURN = '\r';
    private static final char LITERAL_TAB = '\t';
    private static final char LITERAL_NULL = '\0';

    private static final Pattern HEX_PAIR = Pattern.compile("[0-9A-F]{2}");
    private static final Pattern HEX_QUAD = Pattern.compile("[0-9A-F]{4}");
    private static final Pattern HEX_OCTET = Pattern.compile("[0-9A-F]{8}");

    private final EnumSet<Feature> activeFeatures;

    public static final StringEscapeHelper DISABLED = new StringEscapeHelper(EnumSet.noneOf(Feature.class));
    public static final StringEscapeHelper MINIMAL = new StringEscapeHelper(EnumSet.of(Feature.LEGACY));
    public static final StringEscapeHelper EXTENDED = new StringEscapeHelper(EnumSet.allOf(Feature.class));

    public static StringEscapeHelper forMode(final String mode) {
        switch(mode) {
            case "disabled": return DISABLED;
            case "minimal":  return MINIMAL;
            case "extended": return EXTENDED;
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
                case LITERAL_ZERO:
                    if (!activeFeatures.contains(Feature.ZERO_NULL)) { break; }
                    unescaped.append(LITERAL_NULL);
                    continue;

                // BACKSLASH-X CODEPOINTS
                case LITERAL_LOWER_X:
                    if (!activeFeatures.contains(Feature.LOWER_X_CODEPOINT)) { break; }
                    if (escapedLength < i+3 || !HEX_PAIR.matcher(escaped.subSequence(i+1, 1+3)).matches()) { break; }

                    final char codepoint = (char) Integer.parseInt(escaped.subSequence(i+1, i+3).toString(), 16);
                    unescaped.append(codepoint);
                    i += 2; // consume hex pair
                    continue;
                // BACKSLASH-U UNICODE SUPPORT
                case LITERAL_LOWER_U:
                    if (!activeFeatures.contains(Feature.LOWER_U_CODEPOINT)) { break; }
                    if (escapedLength >= i+9 && HEX_OCTET.matcher(escaped.subSequence(i+1,i+9)).matches()) {
                        final char[] chars = Character.toChars(Integer.parseInt(escaped.subSequence(i+1,i+9).toString(), 16));
                        unescaped.append(chars);
                        i += 8;
                        continue;
                    }
                    if (escapedLength >= i+5 && HEX_QUAD.matcher(escaped.subSequence(i+1,i+5)).matches()) {
                        final char[] chars = Character.toChars(Integer.parseInt(escaped.subSequence(i+1,i+5).toString(), 16));
                        unescaped.append(chars);
                        i += 4;
                        continue;
                    }
                    break;

            }

            // Any character following a backslash that does _not_ fit
            // into one of the above will be emitted as-is.
            unescaped.append(seq);
        }

        return unescaped.toString();
    }
}
