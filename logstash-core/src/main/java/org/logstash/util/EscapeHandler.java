package org.logstash.util;

import org.apache.commons.codec.DecoderException;
import org.apache.commons.codec.binary.Hex;

import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.util.regex.Pattern;

public interface EscapeHandler {
    String unescape(String escaped);
    String escape(String unescaped);

    EscapeHandler NONE = new EscapeHandler() {
        @Override
        public String unescape(final String escaped) {
            return escaped;
        }

        @Override
        public String escape(final String unescaped) {
            return unescaped;
        }
    };

    EscapeHandler PERCENT = new EscapeHandler() {
        private final Pattern ESCAPE_REQUIRED_PERCENT_LITERAL = Pattern.compile("%(?=[0-9A-F]{2})");

        @Override
        public String escape(final String unescaped) {
            // When a percent-literal is followed by a pair of hex digits, we must escape it.
            return ESCAPE_REQUIRED_PERCENT_LITERAL.matcher(unescaped).replaceAll("%25")
                    .replace("[", "%5B")
                    .replace("]", "%5D");
        }

        private final Pattern PERCENT_ENCODED_SEQUENCE = Pattern.compile("%[0-9A-F]{2}");
        private final Pattern UNESCAPED_PERCENT_LITERAL = Pattern.compile("%(?![0-9A-F]{2})");

        public String unescape(String escaped) {
            if (!escaped.contains("%")) { return escaped; }
            if (!PERCENT_ENCODED_SEQUENCE.matcher(escaped).find()) { return escaped; }

            // In order to support unescaped percent-literals without implementing
            // our own percent-decoder, we need to detect them and escape them before
            // handing off to java's URLDecoder.
            escaped = UNESCAPED_PERCENT_LITERAL.matcher(escaped).replaceAll("%25");

            return URLDecoder.decode(escaped, StandardCharsets.UTF_8);
        }
    };

    EscapeHandler AMPERSAND = new EscapeHandler() {
        private final Pattern AMPERSAND_ENCODED_SEQUENCE = Pattern.compile("&#([0-9]{2,});");

        @Override
        public String escape(final String unescaped) {
            return unescaped.replaceAll(AMPERSAND_ENCODED_SEQUENCE.pattern(), "&#38;#$1;")
                    .replace("[", "&#91;")
                    .replace("]", "&#93;");
        }

        @Override
        public String unescape(final String escaped) {
            if (!escaped.contains("&")) { return escaped; }

            return AMPERSAND_ENCODED_SEQUENCE.matcher(escaped).replaceAll(matchResult -> {
                final int codePoint = Integer.parseInt(matchResult.group(1));
                final char[] chars = Character.toChars(codePoint);
                return String.copyValueOf(chars);
            });
        }
    };
}
