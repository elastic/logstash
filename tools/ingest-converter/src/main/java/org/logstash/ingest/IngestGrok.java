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

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

public class IngestGrok {

    /**
     * Converts Ingest JSON to LS Grok.
     */
    @SuppressWarnings({"rawtypes", "unchecked"})
    public static String toLogstash(String json, boolean appendStdio) throws JsonProcessingException {
        ObjectMapper mapper = new ObjectMapper();
        TypeReference<HashMap<String, Object>> typeRef = new TypeReference<HashMap<String, Object>>() {};
        final HashMap<String, Object> jsonDefinition = mapper.readValue(json, typeRef);
        final List<Map> processors = (List<Map>) jsonDefinition.get("processors");
        List<String> filters_pipeline = processors.stream().map(IngestGrok::mapProcessor).collect(Collectors.toList());

        return IngestConverter.filtersToFile(
                IngestConverter.appendIoPlugins(filters_pipeline, appendStdio));
    }

    @SuppressWarnings({"rawtypes", "unchecked"})
    private static String mapProcessor(Map processor) {
        return IngestConverter.filterHash(IngestConverter.createHash("grok", grokHash(processor)));
    }

    @SuppressWarnings({"rawtypes", "unchecked"})
    static String grokHash(Map<String, Map> processor) {
        Map grok_data = processor.get("grok");
        String grok_contents = createHashField("match",
                IngestConverter.createField(
                        IngestConverter.quoteString((String) grok_data.get("field")),
                        IngestConverter.createPatternArrayOrField(((List<String>) grok_data.get("patterns")).toArray(new String[0]))
                ));
        if (grok_data.containsKey("pattern_definitions")) {
            grok_contents = IngestConverter.joinHashFields(
                    grok_contents,
                    createPatternDefinitionHash((Map<String, String>) grok_data.get("pattern_definitions"))
            );
        }
        return grok_contents;
    }

    private static String createHashField(String name, String content) {
        return IngestConverter.createField(name, IngestConverter.wrapInCurly(content));
    }

    private static String createPatternDefinitionHash(Map<String, String> definitions) {
        List<String> content = new ArrayList<>();
        for(Map.Entry<String, String> entry : definitions.entrySet()) {
            content.add(IngestConverter.createField(
                    IngestConverter.quoteString(entry.getKey()),
                    IngestConverter.quoteString(entry.getValue())));
        }

        final String patternDefs = content.stream().map(IngestConverter::dotsToSquareBrackets)
                .collect(Collectors.joining("\n"));

        return createHashField(
                "pattern_definitions",
                patternDefs
        );
    }

    public static boolean has_grok(Map<String, Object> processor) {
        return processor.containsKey(get_name());
    }

    public static String get_name() {
        return "grok";
    }
}
