package org.logstash.ackedqueue;

/**
 * A {@link ZstdAwareCompressionCodec} is an {@link CompressionCodec} that can decode deflate-compressed
 * bytes, but performs no compression when encoding.
 */
class ZstdAwareCompressionCodec extends AbstractZstdAwareCompressionCodec {
    private static final ZstdAwareCompressionCodec INSTANCE = new ZstdAwareCompressionCodec();

    static ZstdAwareCompressionCodec getInstance() {
        return INSTANCE;
    }

    @Override
    public byte[] encode(byte[] data) {
        return data;
    }
}
