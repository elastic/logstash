package org.logstash.ackedqueue;

import co.elastic.logstash.api.Metric;

/**
 * A {@link ZstdAwareCompressionCodec} is an {@link CompressionCodec} that can decode deflate-compressed
 * bytes, but performs no compression when encoding.
 */
class ZstdAwareCompressionCodec extends AbstractZstdAwareCompressionCodec {

    public ZstdAwareCompressionCodec(Metric queueMetric) {
        super(queueMetric);
    }

    @Override
    public byte[] encode(byte[] data) {
        return data;
    }
}
