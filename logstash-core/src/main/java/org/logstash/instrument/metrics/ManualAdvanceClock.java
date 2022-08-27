package org.logstash.instrument.metrics;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneId;
import java.util.Objects;
import java.util.concurrent.atomic.AtomicReference;

class ManualAdvanceClock extends Clock {
    private final ZoneId zoneId;
    private final AtomicReference<Instant> currentInstant;

    public ManualAdvanceClock(final Instant currentInstant, final ZoneId zoneId) {
        this(new AtomicReference<>(currentInstant), zoneId);
    }

    public ManualAdvanceClock(final Instant currentInstant) {
        this(currentInstant, null);
    }

    private ManualAdvanceClock(final AtomicReference<Instant> currentInstant, final ZoneId zoneId) {
        this.currentInstant = currentInstant;
        this.zoneId = Objects.requireNonNullElseGet(zoneId, ZoneId::systemDefault);
    }

    @Override
    public ZoneId getZone() {
        return this.zoneId;
    }

    @Override
    public Clock withZone(ZoneId zone) {
        return new ManualAdvanceClock(this.currentInstant, zone);
    }

    @Override
    public Instant instant() {
        return currentInstant.get();
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