package org.logstash.ackedqueue;

import co.elastic.logstash.api.UserMetric;
import org.logstash.instrument.metrics.AbstractMetric;

import java.math.BigDecimal;
import java.math.MathContext;
import java.math.RoundingMode;
import java.util.concurrent.atomic.AtomicReference;

/**
 * It uses {@code long} under the hood, and is capable of handling sustained 1GiB/sec
 * for ~272 years before overflowing.
 */
class AtomicIORatioMetric extends AbstractMetric<Double> implements IORatioMetric {

    public static UserMetric.Factory<IORatioMetric> FACTORY = IORatioMetric.PROVIDER.getFactory(AtomicIORatioMetric::new);

    private static final MathContext LIMITED_PRECISION = new MathContext(4, RoundingMode.HALF_UP);
    private static final ImmutableRatio ZERO = new ImmutableRatio(0L, 0L);

    private final AtomicReference<ImmutableRatio> atomicReference = new AtomicReference<>(ZERO);

    AtomicIORatioMetric(final String name) {
        super(name);
    }

    @Override
    public Value getLifetime() {
        return atomicReference.get();
    }

    @Override
    public void incrementBy(long bytesIn, long bytesOut) {
        this.atomicReference.getAndUpdate((existing) -> existing.incrementedBy(bytesIn, bytesOut));
    }

    @Override
    public Double getValue() {
        final Value snapshot = getLifetime();

        final BigDecimal bytesIn = BigDecimal.valueOf(snapshot.bytesIn());
        final BigDecimal bytesOut = BigDecimal.valueOf(snapshot.bytesOut());

        if (bytesIn.signum() == 0) {
            return switch(bytesOut.signum()) {
                case -1 -> Double.NEGATIVE_INFINITY;
                case  1 -> Double.POSITIVE_INFINITY;
                default -> Double.NaN;
            };
        }

        return bytesOut.divide(bytesIn, LIMITED_PRECISION).doubleValue();
    }

    public void reset() {
        this.atomicReference.set(ZERO);
    }

    public record ImmutableRatio(long bytesIn, long bytesOut) implements Value {
        ImmutableRatio incrementedBy(final long bytesIn, final long bytesOut) {
            try {
                final long combinedBytesIn = Math.addExact(this.bytesIn(), bytesIn);
                final long combinedBytesOut = Math.addExact(this.bytesOut(), bytesOut);

                return new ImmutableRatio(combinedBytesIn, combinedBytesOut);
            } catch (ArithmeticException e) {
                // don't crash, just start over.
                return new ImmutableRatio(bytesIn, bytesOut);
            }
        }
    }
}
