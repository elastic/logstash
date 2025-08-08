package org.logstash.ackedqueue;

/**
 * A {@link DeflateAwareCompressionCodec} is an {@link CompressionCodec} that can decode deflate-compressed
 * bytes, but performs no compression when encoding.
 */
class DeflateAwareCompressionCodec extends AbstractDeflateAwareCompressionCodec {
    private static final DeflateAwareCompressionCodec INSTANCE = new DeflateAwareCompressionCodec();

    static DeflateAwareCompressionCodec getInstance() {
        return INSTANCE;
    }

    @Override
    public byte[] encode(byte[] data) {
        return data;
    }
}
