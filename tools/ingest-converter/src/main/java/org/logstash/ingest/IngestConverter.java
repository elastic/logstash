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
package org.logstash.ingest;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

public class IngestConverter {

    /**
     * Translates the JSON naming pattern (`name.qualifier.sub`) into the LS pattern
     * [name][qualifier][sub] for all applicable tokens in the given string.
     * This function correctly identifies and omits renaming of string literals.
     * @param content to replace naming pattern in
     * @returns {string} with Json naming translated into grok naming
     */
    public static String dotsToSquareBrackets(String content) {
        final Pattern pattern = Pattern.compile("\\(\\?:%\\{.*\\|-\\)");
        final Matcher matcher = pattern.matcher(content);
        List<String> tokens = new ArrayList<>();
        String right = content;
        while (matcher.find()) {
            final int start = matcher.start();
            final int end = matcher.end();
            final String matchContent = content.substring(start, end);
            right = content.substring(end);
            tokens.add(tokenDotsToSquareBrackets(content.substring(0, start)));
            tokens.add(matchContent);
        }
        tokens.add(tokenDotsToSquareBrackets(right));
        return String.join("", tokens);
    }

    private static String tokenDotsToSquareBrackets(String content) {
        //Break out if this is not a naming pattern we convert
        final String adjusted;
        if (Pattern.compile("([\\w_]+\\.)+[\\w_]+").matcher(content).find()) {
            adjusted = content.replaceAll("(\\w*)\\.(\\w*)", "$1][$2")
                    .replaceAll("\\[(\\w+)(}|$)", "[$1]$2")
                    .replaceAll("\\{(\\w+):(\\w+)]", "{$1:[$2]")
                    .replaceAll("^(\\w+)]\\[", "[$1][");
        } else {
            adjusted = content;
        }
        return adjusted;
    }

    public static String quoteString(String content) {
        return "\"" + content.replace("\"", "\\\"") + "\"";
    }

    public static String wrapInCurly(String content) {
        return "{\n" + content + "\n}";
    }

    public static String createField(String fieldName, String content) {
        return fieldName + " => " + content;
    }

    public static String createHash(String fieldName, String content) {
        return fieldName + " " + wrapInCurly(content);
    }

    /**
     * All hash fields in LS start on a new line.
     * @param fields Array of Strings of Serialized Hash Fields
     * @returns {string} Joined Serialization of Hash Fields
     */
    public static String joinHashFields(String... fields) {
        return String.join("\n", fields);
    }

    /**
     * Fixes indentation in LS string.
     * @param content LS string to fix indentation in, that has no indentation intentionally with
     * all lines starting on a token without preceding spaces.
     * @return LS string indented by 3 spaces per level
     */
    public static String fixIndent(String content) {
        final String[] lines = content.split("\n");
        int count = 0;
        for (int i = 0; i < lines.length; i++) {
            if (Pattern.compile("(\\{|\\[)$").matcher(lines[i]).find()) {
                lines[i] = indent(lines[i], count);
                ++count;
            } else if (Pattern.compile("(\\}|\\])$").matcher(lines[i]).find()) {
                --count;
                lines[i] = indent(lines[i], count);
                // Only indent line if previous line ended on relevant control char.
            } else if (i > 0 && Pattern.compile("(=>\\s+\".+\"|,|\\{|\\}|\\[|\\])$").matcher(lines[i - 1]).find()) {
                lines[i] = indent(lines[i], count);
            }
        }

        return String.join("\n", lines);
    }

    private static String indent(String content, int shifts) {
        StringBuilder spacing = new StringBuilder();
        for (int i = 0; i < shifts * 3; i++) {
            spacing.append(" ");
        }
        return spacing.append(content).toString();
    }

    /**
     * Converts Ingest/JSON style pattern array to LS pattern array, performing necessary variable
     * name and quote escaping adjustments.
     * @param patterns Pattern Array in JSON formatting
     * @return Pattern array in LS formatting
     */
    public static String createPatternArray(String... patterns) {
        final String body = Arrays.stream(patterns)
                .map(IngestConverter::dotsToSquareBrackets)
                .map(IngestConverter::quoteString)
                .collect(Collectors.joining(",\n"));
        return "[\n" + body + "\n]";
    }

    public static String createArray(List<String> ingestArray) {
        final String body = ingestArray.stream()
                .map(IngestConverter::quoteString)
                .collect(Collectors.joining(",\n"));
        return "[\n" + body + "\n]";
    }


    /**
     * Converts Ingest/JSON style pattern array to LS pattern array or string if the given array
     * contains a single element only, performing necessary variable name and quote escaping
     * adjustments.
     * @param patterns Pattern Array in JSON formatting
     * @return Pattern array or string in LS formatting
     */
    public static String createPatternArrayOrField(String... patterns) {
        return patterns.length == 1
                ? quoteString(dotsToSquareBrackets(patterns[0]))
                : createPatternArray(patterns);
    }

    public static String filterHash(String contents) {
        return fixIndent(createHash("filter", contents));
    }

    public static String filtersToFile(String... filters) {
        return String.join("\n\n", filters) + "\n";
    }

    /**
     * Does it have an on_failure field?
     * @param processor Json
     * @param name Name of the processor
     * @return true if has on failure
     */
    @SuppressWarnings("rawtypes")
    public static boolean hasOnFailure(Map<String, Map> processor, String name) {
        final List onFailure = (List) processor.get(name).get("on_failure");
        return onFailure != null && !onFailure.isEmpty();
    }

    @SuppressWarnings({"rawtypes", "unchecked"})
    public static List<Map<String, Map>> getOnFailure(Map<String, Map> processor, String name) {
        return (List<Map<String, Map>>) processor.get(name).get("on_failure");
    }

    /**
     * Creates an if clause with the tag name
     * @param tag String tag name to find in [tags] field
     * @param onFailurePipeline The on failure pipeline converted to LS to tack on in the conditional
     * @return a string representing a conditional logic
     */
    public static String createTagConditional(String tag, String onFailurePipeline) {
        return "if " + quoteString(tag) + " in [tags] {\n" +
                onFailurePipeline + "\n" +
                "}";
    }

    public static String getElasticsearchOutput() {
        return fixIndent("output {\n" +
                "elasticsearch {\n" +
                "hosts => \"localhost\"\n" +
                "}\n" +
                "}");
    }

    public static String getStdinInput() {
        return fixIndent("input {\n" +
                "stdin {\n" +
                "}\n" +
                "}");
    }

    public static String getStdoutOutput() {
        return fixIndent("output {\n" +
                "stdout {\n" +
                "codec => \"rubydebug\"\n" +
                "}\n" +
                "}");
    }

    public static String appendIoPlugins(List<String> filtersPipeline, boolean appendStdio) {
        // TODO create unique list to join all
        String filtersPipelineStr = String.join("\n", filtersPipeline);
        if (appendStdio) {
            return String.join("\n", IngestConverter.getStdinInput(), filtersPipelineStr, IngestConverter.getStdoutOutput());
        } else {
            return String.join("\n", filtersPipelineStr, IngestConverter.getElasticsearchOutput());
        }
    }
}
