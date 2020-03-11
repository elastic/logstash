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


package org.logstash.benchmark.cli.util;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JavaType;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import org.logstash.benchmark.cli.ui.LsMetricStats;
import org.openjdk.jmh.util.ListStatistics;

/**
 * Json Utilities.
 */
public final class LsBenchJsonUtil {

    private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper();

    private static final JavaType LS_METRIC_TYPE =
        OBJECT_MAPPER.getTypeFactory().constructMapType(HashMap.class, String.class, Object.class);

    private LsBenchJsonUtil() {
        // Utility Class
    }

    /**
     * Deserializes metrics read from LS HTTP Api.
     * @param data raw bytes read from HTTP API
     * @return Deserialized JSON Map of Metrics
     * @throws IOException On Deserialization Failure
     */
    public static Map<String, Object> deserializeMetrics(final byte[] data) throws IOException {
        return LsBenchJsonUtil.OBJECT_MAPPER.readValue(data, LsBenchJsonUtil.LS_METRIC_TYPE);
    }

    /**
     * Serializes result for storage in Elasticsearch.
     * @param data Measurement Data
     * @param meta Metadata
     * @return JSON String
     * @throws JsonProcessingException On Failure to Serialize
     */
    public static String serializeEsResult(final Map<LsMetricStats, ListStatistics> data,
        final Map<String, Object> meta) throws JsonProcessingException {
        final Map<String, Object> measurement = new HashMap<>(4);
        measurement.put("@timestamp", System.currentTimeMillis());
        final ListStatistics throughput = data.get(LsMetricStats.THROUGHPUT);
        measurement.put("throughput_min", throughput.getMin());
        measurement.put("throughput_max", throughput.getMax());
        measurement.put("throughput_mean", Math.round(throughput.getMean()));
        measurement.put(
            "cpu_usage_mean_percent", Math.round(data.get(LsMetricStats.CPU_USAGE).getMean())
        );
        measurement.put("meta", meta);
        return OBJECT_MAPPER.writeValueAsString(measurement);
    }
}
