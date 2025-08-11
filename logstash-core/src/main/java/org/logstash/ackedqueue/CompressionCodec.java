package org.logstash.ackedqueue;

public interface CompressionCodec {

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
}
