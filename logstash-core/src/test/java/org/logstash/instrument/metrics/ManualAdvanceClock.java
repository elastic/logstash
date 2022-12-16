package org.logstash.instrument.metrics;

import java.time.Duration;
import java.time.Instant;
import java.time.ZoneId;
import java.time.temporal.ChronoUnit;
import java.util.Objects;
import java.util.concurrent.atomic.AtomicReference;

public class ManualAdvanceClock extends TestClock {
    private final ZoneId zoneId;
    private final AtomicReference<Instant> currentInstant;
    private final Instant zeroInstant;

    public ManualAdvanceClock(final Instant currentInstant, final ZoneId zoneId) {
        this(currentInstant, new AtomicReference<>(currentInstant), zoneId);
    }

    public ManualAdvanceClock(final Instant currentInstant) {
        this(currentInstant, null);
    }

    private ManualAdvanceClock(final Instant zeroInstant, final AtomicReference<Instant> currentInstant, final ZoneId zoneId) {
        this.zeroInstant = zeroInstant;
        this.currentInstant = currentInstant;
        this.zoneId = Objects.requireNonNullElseGet(zoneId, ZoneId::systemDefault);
    }

    @Override
    public ZoneId getZone() {
        return this.zoneId;
    }

    @Override
    public TestClock withZone(ZoneId zone) {
        return new ManualAdvanceClock(this.zeroInstant, this.currentInstant, zone);
    }

    @Override
    public Instant instant() {
        return currentInstant.get();
    }

    /**
     * @return an only-incrementing long value, meant as a drop-in replacement
     *         for {@link System#nanoTime()}, using this {@link ManualAdvanceClock}
     *         as the time source, and carrying the same constraints.
     */
    public long nanoTime() {
        return zeroInstant.until(instant(), ChronoUnit.NANOS);
    }

    public void advance(final Duration duration) {
        if (duration.isZero()) {
            return;
        }
        if (duration.isNegative()) {
            throw new IllegalArgumentException("duration must not be negative");
        }
        this.currentInstant.updateAndGet(previous -> previous.plus(duration));
    }
}
