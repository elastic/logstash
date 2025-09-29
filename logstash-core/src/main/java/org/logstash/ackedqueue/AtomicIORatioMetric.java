package org.logstash.ackedqueue;

import co.elastic.logstash.api.UserMetric;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
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
    private static final Logger LOGGER = LogManager.getLogger(AtomicIORatioMetric.class);

    private final AtomicReference<ImmutableRatio> atomicReference = new AtomicReference<>(ZERO);
    private final Logger logger;

    AtomicIORatioMetric(final String name) {
        this(name, LOGGER);
    }

    AtomicIORatioMetric(final String name, final Logger logger) {
        super(name);
        this.logger = logger;
    }

    @Override
    public Value getLifetime() {
        return atomicReference.get();
    }

    @Override
    public void incrementBy(int bytesIn, int bytesOut) {
        if (bytesIn < 0 || bytesOut < 0) {
            logger.warn("cannot decrement IORatioMetric {}", this.getName());
            return;
        }
        this.atomicReference.getAndUpdate((existing) -> doIncrement(existing, bytesIn, bytesOut));
    }

    // test injection
    void setTo(long bytesIn, long bytesOut) {
        this.atomicReference.set(new ImmutableRatio(bytesIn, bytesOut));
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

    private ImmutableRatio doIncrement(final ImmutableRatio existing, final int bytesIn, final int bytesOut) {

        final long combinedBytesIn = existing.bytesIn() + bytesIn;
        final long combinedBytesOut = existing.bytesOut() + bytesOut;

        if (combinedBytesIn < 0 || combinedBytesOut < 0) {
            logger.warn("long overflow; precision will be reduced");
            final long reducedBytesIn = Math.addExact(Math.floorDiv(existing.bytesIn(), 2), bytesIn);
            final long reducedBytesOut = Math.addExact(Math.floorDiv(existing.bytesOut(), 2), bytesOut);

            return new ImmutableRatio(reducedBytesIn, reducedBytesOut);
        }

        return new ImmutableRatio(combinedBytesIn, combinedBytesOut);
    }

    public record ImmutableRatio(long bytesIn, long bytesOut) implements Value { }
}
