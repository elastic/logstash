package org.logstash.ackedqueue;

import co.elastic.logstash.api.Metric;
import co.elastic.logstash.api.NamespacedMetric;
import com.github.luben.zstd.Zstd;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

/**
 * Subclasses of {@link AbstractZstdAwareCompressionCodec} are {@link CompressionCodec}s that are capable
 * of detecting and decompressing deflate-compressed events. When decoding byte sequences that are <em>NOT</em>
 * deflate-compressed, the given bytes are emitted verbatim.
 */
abstract class AbstractZstdAwareCompressionCodec implements CompressionCodec {
    // log from the concrete class
    protected final Logger logger = LogManager.getLogger(this.getClass());

    private final IORatioMetric decodeRatioMetric;
    private final RelativeSpendMetric decodeTimerMetric;

    public AbstractZstdAwareCompressionCodec(Metric queueMetric) {
        final NamespacedMetric decodeNamespace = queueMetric.namespace("compression", "decode");
        decodeRatioMetric = decodeNamespace.namespace("ratio")
                .register("lifetime", AtomicIORatioMetric.FACTORY);
        decodeTimerMetric = decodeNamespace.namespace("spend")
                .register("lifetime", CalculatedRelativeSpendMetric.FACTORY);
    }

    @Override
    public byte[] decode(byte[] data) {
        if (!isZstd(data)) {
            decodeRatioMetric.incrementBy(data.length, data.length);
            return data;
        }
        try {
            final byte[] decoded = decodeTimerMetric.time(() -> Zstd.decompress(data));
            decodeRatioMetric.incrementBy(data.length, decoded.length);
            logger.trace("decoded {} -> {}", data.length, decoded.length);
            return decoded;
        } catch (Exception e) {
            throw new RuntimeException("Exception while decoding", e);
        }
    }

    private static final byte[] ZSTD_FRAME_MAGIC = { (byte) 0x28, (byte) 0xB5, (byte) 0x2F, (byte) 0xFD };

    static boolean isZstd(byte[] data) {
        if (data.length < 4) { return false; }

        for (int i = 0; i < 4; i++) {
            if (data[i] != ZSTD_FRAME_MAGIC[i]) { return false; }
        }

        return true;
    }
}
