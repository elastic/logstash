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

package org.logstash.secret;

import com.google.common.annotations.VisibleForTesting;
import org.apache.logging.log4j.util.Strings;

import java.util.Arrays;
import java.util.List;
import java.util.Objects;
import java.util.regex.Pattern;
import java.util.regex.Matcher;
import java.util.stream.Collectors;

public class KeyValidator {

    @VisibleForTesting
    protected static final List<String> RESTRICTED_SYMBOLS = Arrays.asList("?", "..", "/", "\\", "'", "\"", "$", "*", "|", "<", ">", " ");
    private static final Pattern RESTRICTED_PATTERN = buildPattern();

    private static Pattern buildPattern() {
        String pattern = RESTRICTED_SYMBOLS.stream()
                .map(Pattern::quote)
                .collect(Collectors.joining("|"));
        return Pattern.compile(pattern);
    }

    /**
     * Validates the key against the {@link KeyValidator#RESTRICTED_SYMBOLS} list.
     * Throws {@link IllegalArgumentException} if the key contains any of them.
     * @param key A key to be validated
     * @param keyName A key name mapped to the key
     */
    public static void validateKey(final String key, final String keyName) {
        if (Strings.isBlank(key)) {
            throw new IllegalArgumentException(String.format("%s may not be null or blank", keyName));
        }

        Matcher matcher = RESTRICTED_PATTERN.matcher(key);
        if (matcher.find()) {
            String foundSymbol = matcher.group();
            foundSymbol = Objects.equals(foundSymbol, " ") ? "whitespace" : foundSymbol;
            throw new IllegalArgumentException(String.format("%s can not contain %s", keyName, foundSymbol));
        }
    }
}