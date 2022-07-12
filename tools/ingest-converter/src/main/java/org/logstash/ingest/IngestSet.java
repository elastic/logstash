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

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

public class IngestSet {

    /**
     * Converts Ingest Set JSON to LS mutate filter.
     */
    @SuppressWarnings({"rawtypes", "unchecked"})
    public static String toLogstash(String json, boolean appendStdio) throws JsonProcessingException {
        ObjectMapper mapper = new ObjectMapper();
        TypeReference<HashMap<String, Object>> typeRef = new TypeReference<HashMap<String, Object>>() {};
        final HashMap<String, Object> jsonDefinition = mapper.readValue(json, typeRef);
        final List<Map> processors = (List<Map>) jsonDefinition.get("processors");
        List<String> filters_pipeline = processors.stream().map(IngestSet::mapProcessor).collect(Collectors.toList());

        return IngestConverter.filtersToFile(
                IngestConverter.appendIoPlugins(filters_pipeline, appendStdio));
    }

    @SuppressWarnings({"rawtypes", "unchecked"})
    private static String mapProcessor(Map processor) {
        return IngestConverter.filterHash(IngestConverter.createHash("mutate", setHash(processor)));
    }

    @SuppressWarnings({"rawtypes", "unchecked"})
    static String setHash(Map<String, Map> processor) {
        Map set_json = processor.get("set");
        final Object value = set_json.get("value");
        final Object value_contents;
        if (value instanceof String) {
            value_contents = IngestConverter.quoteString((String) value);
        } else {
            value_contents = value;
        }
        if (set_json.containsKey("if") && set_json.get("if") != null) {
            String painless_condition = (String) set_json.get("if");
            if (!painless_condition.isEmpty()) {
                System.out.println("WARN Found in 'set' processor an 'if' painless condition not translated: " + painless_condition);
            }

        }

        String mutate_contents = IngestConverter.createField(
                IngestConverter.quoteString(IngestConverter.dotsToSquareBrackets((String) set_json.get("field"))),
                value_contents.toString());
        return IngestConverter.createField("add_field", IngestConverter.wrapInCurly(mutate_contents));
    }

    public static boolean has_set(Map<String, Object> processor) {
        return processor.containsKey("set");
    }
}
