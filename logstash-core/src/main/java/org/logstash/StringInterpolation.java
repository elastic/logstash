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

import com.fasterxml.jackson.core.JsonProcessingException;
import org.joda.time.DateTime;
import org.joda.time.DateTimeZone;
import org.joda.time.format.DateTimeFormat;

import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;
import java.util.Optional;

public final class StringInterpolation {

    private static final String TIME_NOW = "TIME_NOW";
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

    public static String evaluate(final co.elastic.logstash.api.Event event, final String template)
        throws JsonProcessingException {
        if (event instanceof Event) {
            return evaluate((Event) event, template);
        } else {
            throw new IllegalStateException("Unknown event concrete class: " + event.getClass().getName());
        }
    }

    public static String evaluate(final Event event, final String template) throws JsonProcessingException {
        int open = template.indexOf("%{");
        int close = template.indexOf('}', open);
        if (open == -1 || close == -1) {
            return template;
        }
        final StringBuilder builder = STRING_BUILDER.get();
        int pos = 0;
        final int len = template.length();
        while (open > -1 && close > -1) {
            if (open > 0) {
                builder.append(template, pos, open);
            }
            if (template.regionMatches(open + 2, "+%s", 0, close - open - 2)) {
                // UNIX-style @timestamp formatter:
                // - `%{+%s}` -> 1234567890
                Timestamp t = event.getTimestamp();
                builder.append(t == null ? "" : t.toInstant().getEpochSecond());
            } else if (template.charAt(open+2) == '{' && (close < len) && template.charAt(close+1) == '}') {
                // JAVA-style @timestamp formatter:
                // - `%{{yyyy-MM-dd}}` -> `2021-08-11`
                // - `%{{YYYY-'W'ww}}` -> `2021-W32`
                // A special pattern to generate a fresh current time
                // - `%{{TIME_NOW}}` -> `2025-01-16T16:57:12.488955Z`
                close = close + 1; // consume extra closing squiggle
                final String pattern = template.substring(open+3, close-1);
                if (pattern.equals(TIME_NOW)) {
                    builder.append(new Timestamp());
                } else {
                    Optional.ofNullable(event.getTimestamp())
                            .map(Timestamp::toInstant)
                            .map(instant -> DateTimeFormatter.ofPattern(pattern)
                                    .withZone(ZoneOffset.UTC)
                                    .format(instant))
                            .ifPresent(builder::append);
                }
            } else if (template.charAt(open + 2) == '+') {
                // JODA-style @timestamp formatter:
                // - `%{+YYYY.MM.dd}` -> `2021-08-11`
                // - `%{+xxxx-'W'ww}  -> `2021-W32`
                final Timestamp t = event.getTimestamp();
                if (t != null) {
                    final String jodaTimeFormatPattern = template.substring(open + 3, close);
                    final org.joda.time.format.DateTimeFormatter jodaDateTimeFormatter = DateTimeFormat.forPattern(jodaTimeFormatPattern).withZone(DateTimeZone.UTC);
                    final DateTime jodaTimestamp = new DateTime(t.toInstant().toEpochMilli(), DateTimeZone.UTC);
                    final String formattedTimestamp = jodaTimestamp.toString(jodaDateTimeFormatter);
                    builder.append(formattedTimestamp);
                }
            } else {
                final String found = template.substring(open + 2, close);
                final Object value = event.getField(found);
                if (value != null) {
                    if (value instanceof List) {
                        builder.append(KeyNode.join((List) value, ","));
                    } else if (value instanceof Map) {
                        builder.append(ObjectMappers.JSON_MAPPER.writeValueAsString(value));
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
        if (pos < len) {
            builder.append(template, pos, len);
        }
        return builder.toString();
    }

}
