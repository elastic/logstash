package org.logstash.instrument.witness;

import com.fasterxml.jackson.core.JsonGenerator;
import org.logstash.instrument.metrics.Metric;
import org.logstash.instrument.metrics.gauge.GaugeMetric;
import org.logstash.instrument.metrics.gauge.RubyTimeStampGauge;

import java.io.IOException;

/**
 * Similar to the {@link java.util.function.Consumer} functional interface this is expected to operate via side effects. Differs from {@link java.util.function.Consumer} in that
 * this is stricter typed, and allows for a checked {@link IOException}.
 *
 * @param <T> The type of {@link GaugeMetric} to serialize
 */
@FunctionalInterface
public interface MetricSerializer<T extends Metric<?>> {

    /**
     * Performs this operation on the given argument.
     *
     * @param t the input argument
     */
    void serialize(T t) throws IOException;

    /**
     * Helper class to create a functional fluent api.
     * Usage example: {@code MetricSerializer.Get.numberSerializer(gen).serialize(99);}
     */
    class Get {
        /**
         * Proper way to serialize a {@link Number} type metric to JSON
         *
         * @param gen The {@link JsonGenerator} used to generate JSON
         * @return the {@link MetricSerializer} which is the function used to serialize the metric
         */
        public static MetricSerializer<Metric<Number>> numberSerializer(JsonGenerator gen) {
            return m -> {
                if (m != null) {
                    Number value = m.getValue();
                    gen.writeObjectField(m.getName(), value == null ? 0 : value);
                }
            };
        }

        /**
         * Proper way to serialize a {@link Long} type metric to JSON
         *
         * @param gen The {@link JsonGenerator} used to generate JSON
         * @return the {@link MetricSerializer} which is the function used to serialize the metric
         */
        public static MetricSerializer<Metric<Long>> longSerializer(JsonGenerator gen) {
            return m -> {
                if (m != null) {
                    Long value = m.getValue();
                    gen.writeNumberField(m.getName(), value == null ? 0 : value);
                }
            };
        }

        /**
         * Proper way to serialize a {@link Boolean} type metric to JSON
         *
         * @param gen The {@link JsonGenerator} used to generate JSON
         * @return the {@link MetricSerializer} which is the function used to serialize the metric
         */
        public static MetricSerializer<Metric<Boolean>> booleanSerializer(JsonGenerator gen) {
            return m -> {
                if (m != null) {
                    Boolean value = m.getValue();
                    gen.writeBooleanField(m.getName(), value == null ? false : value);
                }
            };
        }

        /**
         * Proper way to serialize a {@link String} type metric to JSON
         *
         * @param gen The {@link JsonGenerator} used to generate JSON
         * @return the {@link MetricSerializer} which is the function used to serialize the metric
         */
        public static MetricSerializer<Metric<String>> stringSerializer(JsonGenerator gen) {
            return m -> {
                if (m != null) {
                    gen.writeStringField(m.getName(), m.getValue());
                }
            };
        }

        /**
         * Proper way to serialize a {@link RubyTimeStampGauge} type metric to JSON that should emit a {@code null} JSON value if missing
         *
         * @param gen The {@link JsonGenerator} used to generate JSON
         * @return the {@link MetricSerializer} which is the function used to serialize the metric
         */
        public static MetricSerializer<RubyTimeStampGauge> timestampSerializer(JsonGenerator gen) {
            return m -> {
                if (m != null) {
                    gen.writeStringField(m.getName(), m.getValue() != null ? m.getValue().toString() : null);
                }
            };
        }
    }
}
