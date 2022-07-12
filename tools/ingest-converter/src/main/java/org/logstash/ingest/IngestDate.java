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

public class IngestDate {

    /**
     * Converts Ingest Date JSON to LS Date filter.
     */
    @SuppressWarnings({"rawtypes", "unchecked"})
    public static String toLogstash(String json, boolean appendStdio) throws JsonProcessingException {
        ObjectMapper mapper = new ObjectMapper();
        TypeReference<HashMap<String, Object>> typeRef = new TypeReference<HashMap<String, Object>>() {};
        final HashMap<String, Object> jsonDefinition = mapper.readValue(json, typeRef);
        final List<Map> processors = (List<Map>) jsonDefinition.get("processors");
        List<String> filters_pipeline = processors.stream().map(IngestDate::mapProcessor).collect(Collectors.toList());

        return IngestConverter.filtersToFile(
                IngestConverter.appendIoPlugins(filters_pipeline, appendStdio));
    }

    @SuppressWarnings({"rawtypes", "unchecked"})
    private static String mapProcessor(Map processor) {
        return IngestConverter.filterHash(IngestConverter.createHash("date", dateHash(processor)));
    }

    @SuppressWarnings({"rawtypes", "unchecked"})
    static String dateHash(Map<String, Map> processor) {
        Map date_json = processor.get("date");
        List<String> formats = (List<String>) date_json.get("formats");

        final String firstElem = IngestConverter.dotsToSquareBrackets((String) date_json.get("field"));
        List<String> match_contents = new ArrayList<>();
        match_contents.add(firstElem);
        for (String f : formats) {
            match_contents.add(f);
        }
        String date_contents = IngestConverter.createField(
                "match",
                IngestConverter.createPatternArray(match_contents.toArray(new String[0])));
        if (JsUtil.isNotEmpty((String) date_json.get("target_field"))) {
            String target = IngestConverter.createField(
                    "target",
                    IngestConverter.quoteString(
                            IngestConverter.dotsToSquareBrackets((String) date_json.get("target_field"))
                    )
            );
            date_contents = IngestConverter.joinHashFields(date_contents, target);
        }
        if (JsUtil.isNotEmpty((String) date_json.get("timezone"))) {
            String timezone = IngestConverter.createField(
                    "timezone",
                    IngestConverter.quoteString((String) date_json.get("timezone"))
            );
            date_contents = IngestConverter.joinHashFields(date_contents, timezone);
        }
        if (JsUtil.isNotEmpty((String) date_json.get("locale"))) {
            String locale = IngestConverter.createField(
                    "locale",
                    IngestConverter.quoteString((String) date_json.get("locale"))
            );
            date_contents = IngestConverter.joinHashFields(date_contents, locale);
        }
        return date_contents;
    }

    public static boolean has_date(Map<String, Object> processor) {
        return processor.containsKey("date");
    }
}
