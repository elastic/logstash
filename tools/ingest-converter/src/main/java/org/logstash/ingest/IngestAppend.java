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

public class IngestAppend {

    /**
     * Converts Ingest Append JSON to LS mutate filter.
     */
    @SuppressWarnings({"rawtypes", "unchecked"})
    public static String toLogstash(String json, boolean appendStdio) throws JsonProcessingException {
        ObjectMapper mapper = new ObjectMapper();
        TypeReference<HashMap<String, Object>> typeRef = new TypeReference<HashMap<String, Object>>() {};
        final HashMap<String, Object> jsonDefinition = mapper.readValue(json, typeRef);
        final List<Map> processors = (List<Map>) jsonDefinition.get("processors");
        List<String> filters_pipeline = processors.stream().map(IngestAppend::mapProcessor).collect(Collectors.toList());

        return IngestConverter.filtersToFile(
                IngestConverter.appendIoPlugins(filters_pipeline, appendStdio));
    }

    @SuppressWarnings({"rawtypes", "unchecked"})
    private static String mapProcessor(Map processor) {
        return IngestConverter.filterHash(IngestConverter.createHash("mutate", appendHash(processor)));
    }

    @SuppressWarnings({"rawtypes", "unchecked"})
    static String appendHash(Map<String, Map> processor) {
        Map append_json = processor.get("append");
        Object value = append_json.get("value");
        Object value_contents;
        if (value instanceof List) {
            value_contents = IngestConverter.createArray((List) value);
        } else {
            value_contents = IngestConverter.quoteString((String) value);
        }
        Object mutate_contents = IngestConverter.createField(
                IngestConverter.quoteString(IngestConverter.dotsToSquareBrackets((String) append_json.get("field"))),
                (String) value_contents);
        return IngestConverter.createField("add_field", IngestConverter.wrapInCurly((String) mutate_contents));
    }

    public static boolean has_append(Map<String, Object> processor) {
        return processor.containsKey("append");
    }
}
