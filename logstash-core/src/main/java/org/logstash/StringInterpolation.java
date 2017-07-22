package org.logstash;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.io.IOException;
import java.util.List;
import java.util.Map;
import org.joda.time.DateTimeZone;
import org.joda.time.format.DateTimeFormat;

public final class StringInterpolation {
    
    private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper();

    private static final ThreadLocal<StringBuilder> STRING_BUILDER =
        new ThreadLocal<StringBuilder>() {
            @Override
            protected StringBuilder initialValue() {
                return new StringBuilder();
            }

            @Override
            public StringBuilder get() {
                StringBuilder b = super.get();
                b.setLength(0); // clear/reset the buffer
                return b;
            }

        };
    
    private StringInterpolation() {
        // Utility Class
    }

    public static String evaluate(final Event event, final String template) throws IOException {
        int open = template.indexOf("%{");
        int close = template.indexOf('}', open);
        if (open == -1 || close == -1) {
            return template;
        }
        final StringBuilder builder = STRING_BUILDER.get();
        int pos = 0;
        while (open > -1 && close > -1) {
            if (open > 0) {
                builder.append(template, pos, open);
            }
            if (template.regionMatches(open + 2, "+%s", 0, close - open - 2)) {
                builder.append(event.getTimestamp().getTime().getMillis() / 1000L);
            } else if (template.charAt(open + 2) == '+') {
                builder.append(
                    event.getTimestamp().getTime().toString(
                        DateTimeFormat.forPattern(template.substring(open + 3, close))
                            .withZone(DateTimeZone.UTC)
                    ));
            } else {
                final String found = template.substring(open + 2, close);
                final Object value = event.getField(found);
                if (value != null) {
                    if (value instanceof List) {
                        builder.append(KeyNode.join((List) value, ","));
                    } else if (value instanceof Map) {
                        builder.append(OBJECT_MAPPER.writeValueAsString(value));
                    } else {
                        builder.append(value.toString());
                    }
                } else {
                    builder.append("%{").append(found).append('}');
                }
            }
            pos = close + 1;
            open = template.indexOf("%{", pos);
            close = template.indexOf('}', open);
        }
        final int len = template.length();
        if (pos < len) {
            builder.append(template, pos, len);
        }
        return builder.toString();
    }

}
