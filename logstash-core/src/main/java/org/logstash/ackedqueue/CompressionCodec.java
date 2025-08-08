package org.logstash.ackedqueue;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.util.zip.Deflater;

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

    static CompressionCodec fromConfigValue(final String configValue) {
        return fromConfigValue(configValue, LOGGER);
    }

    static CompressionCodec fromConfigValue(final String configValue, final Logger logger) {
        return switch (configValue) {
            case "disabled" -> {
                logger.warn("compression support has been disabled");
                yield CompressionCodec.NOOP;
            }
            case "none" -> {
                logger.info("compression support is enabled (read-only)");
                yield DeflateAwareCompressionCodec.getInstance();
            }
            case "speed" -> {
                logger.info("compression support is enabled (goal: speed)");
                yield new DeflateEnabledCompressionCodec(Deflater.BEST_SPEED);
            }
            case "balanced" -> {
                logger.info("compression support is enabled (goal: balanced)");
                yield new DeflateEnabledCompressionCodec(Deflater.DEFAULT_COMPRESSION);
            }
            case "size" -> {
                logger.info("compression support is enabled (goal: size)");
                yield new DeflateEnabledCompressionCodec(Deflater.BEST_COMPRESSION);
            }
            default -> throw new IllegalArgumentException(String.format("Unsupported compression setting `%s`", configValue));
        };
    }
}
