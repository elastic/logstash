package org.logstash.ackedqueue;

import co.elastic.logstash.api.Metric;
import co.elastic.logstash.api.NamespacedMetric;
import com.github.luben.zstd.Zstd;

import java.util.Locale;

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

    private final IORatioMetric encodeRatioMetric;
    private final RelativeSpendMetric encodeTimerMetric;

    ZstdEnabledCompressionCodec(final Goal internalLevel, final Metric queueMetric) {
        super(queueMetric);
        this.internalLevel = internalLevel.internalLevel;

        final NamespacedMetric encodeNamespace = queueMetric.namespace("compression", "encode");
        encodeNamespace.gauge("goal", internalLevel.name().toLowerCase(Locale.ROOT));
        encodeRatioMetric = encodeNamespace.namespace("ratio")
                .register("lifetime", AtomicIORatioMetric.FACTORY);
        encodeTimerMetric = encodeNamespace.namespace("spend")
                .register("lifetime", CalculatedRelativeSpendMetric.FACTORY);
    }

    @Override
    public byte[] encode(byte[] data) {
        try {
            final byte[] encoded = encodeTimerMetric.time(() -> Zstd.compress(data, internalLevel));
            encodeRatioMetric.incrementBy(data.length, encoded.length);
            logger.trace("encoded {} -> {}", data.length, encoded.length);
            return encoded;
        } catch (Exception e) {
            throw new RuntimeException("Exception while encoding", e);
        }
    }
}
