package org.logstash.ackedqueue;

import com.github.luben.zstd.Zstd;

/**
 * A {@link ZstdEnabledCompressionCodec} is a {@link CompressionCodec} that can decode deflate-compressed
 * bytes and performs deflate compression when encoding.
 */
class ZstdEnabledCompressionCodec extends AbstractZstdAwareCompressionCodec implements CompressionCodec {
    public enum Goal {
        FASTEST(-7),
        SPEED(-1),
        BALANCED(3),
        HIGH(14),
        SIZE(22),
        ;

        private int internalLevel;

        Goal(final int internalLevel) {
            this.internalLevel = internalLevel;
        }
    }

    private final int internalLevel;

    ZstdEnabledCompressionCodec(final Goal internalLevel) {
        this.internalLevel = internalLevel.internalLevel;
    }

    @Override
    public byte[] encode(byte[] data) {
        try {
            final byte[] encoded = Zstd.compress(data, internalLevel);
            logger.trace("encoded {} -> {}", data.length, encoded.length);
            return encoded;
        } catch (Exception e) {
            throw new RuntimeException("Exception while encoding", e);
        }
    }
}
