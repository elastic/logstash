package org.logstash.instrument.metrics;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.concurrent.atomic.AtomicReference;

/**
 * An {@link HistoricMetric} contains sufficient historic information about a metric to provide
 * rate-of-change information at several granularities (current, 1-minute, 5-minute, 15-minute, and lifetime).
 *
 * It is threadsafe and nonblocking, optimized first for read performance, and second for write performance.
 *
 * Its implementation is much like a singly-linked list, with new entries being inserted at the tail.
 * This directionality allows us to maintain an efficient insertion-time cache of nodes by age and
 * to compact expired entries without full iteration.
 * It is tolerant to a reasonable magnitude of out-of-order insertions.
 *
 * At insertion time, we maintain links to useful nodes, rotating them forward as needed to avoid full-scale
 * iteration in either read- or write-modes. These nodes are defined as the _youngest_ node satisfying their
 * category's minimum time threshold, and their accuracy is dependent on regularly-scheduled _captures_ of the
 * underlying metrics.
 */
public class HistoricMetric<T extends Number> {

    // Test Dependency Injection
    private final Clock clock;

    // Metric Sources
    private final Metric<T> numeratorMetric;
    private final Metric<Long> denominatorMetric;

    // Oldest and Newest nodes in linked list. Oldest *usable* capture is head.next
    private final Capture head = new Capture(null, null, null);
    private final AtomicReference<Capture> tail = new AtomicReference<>(head);

    // Important intermediate nodes in our linked list
    private final QuickReference quickInstant = new QuickReference("current", Duration.ofSeconds(1));
    private final QuickReference quickOneMinute = new QuickReference("last_1_minute", Duration.ofMinutes(1));
    private final QuickReference quickFiveMinutes = new QuickReference("last_5_minutes", Duration.ofMinutes(5));
    private final QuickReference quickFifteenMinutes = new QuickReference("last_15_minutes", Duration.ofMinutes(15));
    private final QuickReference quickLifetime = new QuickLifetimeReference("lifetime");

    // update- and retrieve-order quick reference lists.
    private final List<QuickReference> quickUpdateReferences = List.of(quickLifetime, quickInstant, quickOneMinute, quickFiveMinutes, quickFifteenMinutes);
    private final List<QuickReference> quickReadReferences =   List.of(quickInstant, quickOneMinute, quickFiveMinutes, quickFifteenMinutes, quickLifetime);

    // Safeguard for reads against a dead writer
    private final AtomicReference<Instant> lastCaptured = new AtomicReference<>();
    private static final Duration STALENESS_THRESHOLD = Duration.ofSeconds(10);

    public HistoricMetric(Metric<T> numeratorMetric, Metric<Long> denominatorMetric) {
        this(Clock.systemUTC(), numeratorMetric, denominatorMetric);
    }

    public HistoricMetric(Metric<T> metric) {
        this(Clock.systemUTC(), metric);
    }

    HistoricMetric(Clock clock, Metric<T> numeratorMetric, Metric<Long> denominatorMetric) {
        this.clock = Objects.requireNonNull(clock, "clock must not be null");
        this.numeratorMetric = Objects.requireNonNull(numeratorMetric, "numeratorMetric must not be null");
        this.denominatorMetric = Objects.requireNonNullElseGet(denominatorMetric, () -> new UptimeMetric(clock, null));
    }

    HistoricMetric(Clock clock, Metric<T> metric) {
        this(clock, metric, null);
    }

    // TODO: recording of an HistoricMetric will need to be scheduled on a repeating cadence
    public void capture() {
        capture(clock.instant(), numeratorMetric.getValue(), denominatorMetric.getValue());
    }

    void capture(final Instant timestamp, final T numerator, final Long denominator) {
        final Capture capture = new Capture(timestamp, numerator, denominator);
        final Capture previousTail = this.tail.getAndSet(capture);
        previousTail.next.set(capture);

        this.lastCaptured.set(timestamp);

        // rotate our quick references in ascending age order,
        // bailing entirely if we are too young to warrant continuing
        for (QuickReference quickReference : quickUpdateReferences) {
            if (quickReference.rotate(timestamp) == false) { return; }
        }

        // trim out elements that are no longer necessary
        compact();
    }

    private void compact() {
        final Capture quick_15 = quickFifteenMinutes.capture.get();
        final Capture quick_lifetime = quickLifetime.capture.get();
        if ((Objects.isNull(quick_15) == false) && (Objects.isNull(quick_lifetime) == false)) {
            quick_lifetime.next.set(quick_15);
        }
    }

    public Map<String,Double> availableRates() {
        // staleness safety mechanism ensures at least one recent-ish capture
        final Instant lc = lastCaptured.get();
        if (Objects.isNull(lc) || lc.isBefore(clock.instant().minus(STALENESS_THRESHOLD))) {
            capture();
        }

        final Map<String, Double> rates = new HashMap<>();

        final Capture tailCapture = tail.get();
        if (tailCapture == head) {
            throw new IllegalStateException("No captures to compare!");
        }

        for (QuickReference quickReference : quickReadReferences) {
            final Double rate = tailCapture.calculateRate(quickReference.capture.get());
            if (Objects.nonNull(rate)) {
                rates.put(quickReference.description, rate);
            }
        }

        return rates;
    }

    /**
     * A {@link Capture} is a node in the {@link HistoricMetric}'s internal linked list.
     *
     * It maintains the timestamp of capture, along with the numerator and denominator metrics values
     * at time of capture, so that it can be compared against another {@link Capture} to produce a rate
     * of numerator growth relative to the denominator.
     */
    private class Capture {
        private final AtomicReference<Capture> next = new AtomicReference<>();

        private final T numerator;
        private final Long denominator;

        private final Instant timestamp;

        Capture(final Instant timestamp, final T numerator, final Long denominator) {
            this.timestamp = timestamp;
            this.numerator = numerator;
            this.denominator = denominator;
        }

        Double calculateRate(final Capture baseline) {
            if (Objects.isNull(baseline)) { return null; }
            if (baseline == this) { return null; }

            final double deltaNumerator = this.numerator.doubleValue() - baseline.numerator.doubleValue();
            final long deltaDenominator = this.denominator - baseline.denominator;

            return deltaNumerator / deltaDenominator;
        }

        // seeks _forward_ on the timeline, returning the _last_ candidate that is older than the provided threshold.
        // because strict insertion order is not guaranteed, this may return an entry that is _near_ the boundary.
        // returns null if this node is not older than the threshold
        Capture seekAhead(final Instant threshold) {
            Capture youngestEligible = null;
            Capture candidate = this;

            while ((candidate != null) && (candidate.timestamp != null) && candidate.timestamp.isBefore(threshold)) {
                youngestEligible = candidate;
                candidate = candidate.next.get();
            }

            return youngestEligible;
        }
    }

    /**
     * A {@link QuickReference} is effectively a named {@link Capture} for a time-frame relative
     * to the ever-moving current timestamp.
     *
     * It provides functionality for *rotating* forward in the {@link HistoricMetric}'s internal
     * linked list of {@link Capture}s to ensure it references the youngest {@link Capture} that is
     * older than its {@code minimumAge}, or {@code null} if there is no qualifying {@link Capture}.
     */
    private class QuickReference {
        protected final AtomicReference<Capture> capture = new AtomicReference<>();

        private final Duration minimumAge;
        private final String description;

        QuickReference(String description, Duration minimumAge) {
            this.minimumAge = minimumAge;
            this.description = description;
        }

        boolean rotate(final Instant currentTimestamp) {
            Capture capture = this.capture.updateAndGet(current -> Objects.requireNonNullElse(current, head).seekAhead(currentTimestamp.minus(minimumAge)));
            return Objects.nonNull(capture);
        }
    }

    /**
     * A QuickLifetimeReference is a special kind of QuickReference
     */
    private class QuickLifetimeReference extends QuickReference {
        public QuickLifetimeReference(String description) {
            super(description, null);
        }

        @Override
        boolean rotate(final Instant currentTimestamp) {
            Capture capture = this.capture.updateAndGet(current -> Objects.nonNull(current) ? current : head.next.get());
            return Objects.nonNull(capture);
        }
    }
}
