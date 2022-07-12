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

public class IngestJson {

    /**
     * Converts Ingest json processor to LS json filter.
     */
    @SuppressWarnings({"rawtypes", "unchecked"})
    public static String toLogstash(String json, boolean appendStdio) throws JsonProcessingException {
        ObjectMapper mapper = new ObjectMapper();
        TypeReference<HashMap<String, Object>> typeRef = new TypeReference<HashMap<String, Object>>() {};
        final HashMap<String, Object> jsonDefinition = mapper.readValue(json, typeRef);
        final List<Map> processors = (List<Map>) jsonDefinition.get("processors");
        List<String> filters_pipeline = processors.stream().map(IngestJson::mapProcessor).collect(Collectors.toList());

        return IngestConverter.filtersToFile(
                IngestConverter.appendIoPlugins(filters_pipeline, appendStdio));
    }

    @SuppressWarnings({"rawtypes", "unchecked"})
    private static String mapProcessor(Map processor) {
        return IngestConverter.filterHash(IngestConverter.createHash("json", jsonHash(processor)));
    }

    @SuppressWarnings({"rawtypes", "unchecked"})
    static String jsonHash(Map<String, Map> processor) {
        Map json_data = processor.get("json");

        List<String> parts = new ArrayList();
        parts.add(IngestConverter.createField("source",
                IngestConverter.quoteString(
                        IngestConverter.dotsToSquareBrackets((String) json_data.get("field"))
                )
        ));

        if (json_data.containsKey("target_field")) {
            parts.add(IngestConverter.createField(
                    "target",
                    IngestConverter.quoteString(
                            IngestConverter.dotsToSquareBrackets((String) json_data.get("target_field"))
                    )
            ));
        }
        return IngestConverter.joinHashFields(parts.toArray(new String[0]));
    }

    public static boolean has_json(Map<String, Object> processor) {
        return processor.containsKey("json");
    }
}
