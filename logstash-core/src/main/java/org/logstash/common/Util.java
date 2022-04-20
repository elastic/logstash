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


package org.logstash.common;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.function.Function;
import java.util.regex.MatchResult;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class Util {
    // Modified from http://stackoverflow.com/a/11009612/11105

    public static MessageDigest defaultMessageDigest() {
        try {
            return MessageDigest.getInstance("SHA-256");
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException(e);
        }
    }

    public static String digest(String base) {
        MessageDigest digest = defaultMessageDigest();
        byte[] hash = digest.digest(base.getBytes(StandardCharsets.UTF_8));
        return bytesToHexString(hash);
    }

    public static String bytesToHexString(byte[] bytes) {
        StringBuilder hexString = new StringBuilder();

        for (byte aHash : bytes) {
            String hex = Integer.toHexString(0xff & aHash);
            if (hex.length() == 1) hexString.append('0');
            hexString.append(hex);
        }

        return hexString.toString();
    }

    /**
     * Replace the given regex with a new value based on the given function
     * @param input The string to search
     * @param pattern regex pattern string
     * @param matchSubstituter function that does the replacement based on the match
     * @return new string, with substitutions
     */
    public static String gsub(final String input, final String pattern, Function<MatchResult, String> matchSubstituter) {
        return gsub(input, Pattern.compile(pattern), matchSubstituter);
    }

    /**
     * Replace the given regex with a new value based on the given function
     * @param input The string to search
     * @param pattern Compiled regex pattern
     * @param matchSubstituter function that does the replacement based on the match
     * @return new string, with substitutions
     */
    public static String gsub(final String input, final Pattern pattern, Function<MatchResult, String> matchSubstituter) {
        final StringBuilder output = new StringBuilder();
        final Matcher matcher = pattern.matcher(input);

        while (matcher.find()) {
            // Add the non-matched text preceding the match to the output
            output.append(input, matcher.regionStart(), matcher.start());

            // Add the substituted match to the output
            output.append(matchSubstituter.apply(matcher.toMatchResult()));

            // Move the matched region to after the match
            matcher.region(matcher.end(), input.length());
        }

        // slurp remaining into output
        output.append(input, matcher.regionStart(), input.length());

        return output.toString();
    }
}
