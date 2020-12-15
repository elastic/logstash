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
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

public class IngestPipeline {

    /**
     * Converts Ingest JSON to LS.
     */
    @SuppressWarnings({"rawtypes", "unchecked"})
    public static String toLogstash(String json, boolean appendStdio) throws JsonProcessingException {
        ObjectMapper mapper = new ObjectMapper();
        TypeReference<HashMap<String, Object>> typeRef = new TypeReference<HashMap<String, Object>>() {};
        final HashMap<String, Object> jsonDefinition = mapper.readValue(json, typeRef);
        final List<Map> processors = (List<Map>) jsonDefinition.get("processors");
        List<String> filters_pipeline = processors.stream().map(IngestPipeline::mapProcessor).collect(Collectors.toList());

        String logstash_pipeline = IngestConverter.filterHash(
                IngestConverter.joinHashFields(filters_pipeline.toArray(new String[0])));

        return IngestConverter.filtersToFile(
                IngestConverter.appendIoPlugins(Collections.singletonList(logstash_pipeline), appendStdio));
    }

    @SuppressWarnings({"rawtypes", "unchecked"})
    private static String mapProcessor(Map processor) {
        List<String> filter_blocks = new ArrayList<>();
        if (IngestGrok.has_grok(processor)) {
            filter_blocks.add(IngestConverter.createHash(IngestGrok.get_name(), IngestGrok.grokHash(processor)));

            if (IngestConverter.hasOnFailure(processor, IngestGrok.get_name())) {
                filter_blocks.add(
                        handle_on_failure_pipeline(
                                IngestConverter.getOnFailure(processor, IngestGrok.get_name()),
                                "_grokparsefailure"
                        )
                );
            }
        }
        boolean processed = false;
        if (IngestDate.has_date(processor)) {
            filter_blocks.add(
                    IngestConverter.createHash("date", IngestDate.dateHash(processor))
            );
            processed = true;
        }
        if (IngestGeoIp.has_geoip(processor)) {
            filter_blocks.add(
                    IngestConverter.createHash("geoip", IngestGeoIp.geoIpHash(processor))
            );
            processed = true;
        }
        if (IngestConvert.has_convert(processor)) {
            filter_blocks.add(
                    IngestConverter.createHash("mutate", IngestConvert.convertHash(processor))
            );
            processed = true;
        }
        if (IngestGsub.has_gsub(processor)) {
            filter_blocks.add(
                    IngestConverter.createHash("mutate", IngestGsub.gsubHash(processor))
            );
            processed = true;
        }
        if (IngestAppend.has_append(processor)) {
            filter_blocks.add(
                    IngestConverter.createHash("mutate", IngestAppend.appendHash(processor))
            );
            processed = true;
        }
        if (IngestJson.has_json(processor)) {
            filter_blocks.add(
                    IngestConverter.createHash("json", IngestJson.jsonHash(processor))
            );
            processed = true;
        }
        if (IngestRename.has_rename(processor)) {
            filter_blocks.add(
                    IngestConverter.createHash("mutate", IngestRename.renameHash(processor))
            );
            processed = true;
        }
        if (IngestLowercase.has_lowercase(processor)) {
            filter_blocks.add(
                    IngestConverter.createHash("mutate", IngestLowercase.lowercaseHash(processor))
            );
            processed = true;
        }
        if (IngestSet.has_set(processor)) {
            filter_blocks.add(
                    IngestConverter.createHash("mutate", IngestSet.setHash(processor))
            );
            processed = true;
        }
        if (!processed) {
            System.out.println("WARN Found unrecognized processor named: " + processor.keySet().iterator().next());
        }
        return IngestConverter.joinHashFields(filter_blocks.toArray(new String[0]));
    }

    @SuppressWarnings({"rawtypes", "unchecked"})
    public static String  handle_on_failure_pipeline(List<Map> on_failure_json, String tag_name) {
        final List<String> mapped = on_failure_json.stream().map(IngestPipeline::mapProcessor).collect(Collectors.toList());
        return IngestConverter.createTagConditional(tag_name,
                IngestConverter.joinHashFields(mapped.toArray(new String[0]))
        );
    }
}
