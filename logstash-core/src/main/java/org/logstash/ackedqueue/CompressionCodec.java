package org.logstash.ackedqueue;

import co.elastic.logstash.api.Metric;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.logstash.ackedqueue.ZstdEnabledCompressionCodec.Goal;
import org.logstash.plugins.NamespacedMetricImpl;

public interface CompressionCodec {
    Logger LOGGER = LogManager.getLogger(CompressionCodec.class);

    byte[] encode(byte[] data);
    byte[] decode(byte[] data);

    /**
     * The {@link CompressionCodec#NOOP} is a {@link CompressionCodec} that
     * does nothing when encoding and decoding. It is only meant to be activated
     * as a safety-latch in the event of compression being broken.
     */
    CompressionCodec NOOP = new CompressionCodec() {
        @Override
        public byte[] encode(byte[] data) {
            return data;
        }

        @Override
        public byte[] decode(byte[] data) {
            return data;
        }
    };

    @FunctionalInterface
    interface Factory {
        CompressionCodec create(final Metric metric);
        default CompressionCodec create() {
            return create(NamespacedMetricImpl.getNullMetric());
        }
    }

    static CompressionCodec.Factory fromConfigValue(final String configValue, final Logger logger) {
        return switch(configValue) {
            case "disabled" -> (metric) -> {
                logger.warn("compression support has been disabled");
                return CompressionCodec.NOOP;
            };
            case "none" -> (metric) -> {
                logger.info("compression support is enabled (read-only)");
                return new ZstdAwareCompressionCodec(metric);
            };
            case "speed" -> (metric) -> {
                logger.info("compression support is enabled (goal: speed)");
                return new ZstdEnabledCompressionCodec(Goal.SPEED, metric);
            };
            case "balanced" -> (metric) -> {
                logger.info("compression support is enabled (goal: balanced)");
                return new ZstdEnabledCompressionCodec(Goal.BALANCED, metric);
            };
            case "size" -> (metric) -> {
                logger.info("compression support is enabled (goal: size)");
                return new ZstdEnabledCompressionCodec(Goal.SIZE, metric);
            };
            default -> throw new IllegalArgumentException(String.format("Unsupported compression setting `%s`", configValue));
        };
    }

    static CompressionCodec.Factory fromConfigValue(final String configValue) {
        return fromConfigValue(configValue, LOGGER);
    }
}
