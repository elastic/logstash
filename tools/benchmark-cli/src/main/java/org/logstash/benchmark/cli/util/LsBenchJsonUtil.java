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
