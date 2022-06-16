package org.logstash.instrument.metrics;

import java.time.Clock;
import java.time.Instant;
import java.util.HashMap;
import java.util.Map;
import java.util.Objects;
import java.util.concurrent.atomic.AtomicReference;

/**
 * An {@link HistoricMetric} contains sufficient historic information about a metric to provide
 * rate-of-change information at several granularities (current, 1-minute, 5-minute, 15-minute, and lifetime).
 *
 * It is threadsafe, optimized first for read performance, and second for write performance.
 *
 * Its implementation is much like a singularly-linked list, with older entries linking to newer entries.
 * This directionality allows us to keep track of nodes of a certain age, and to efficiently rotate those links
 * to new nodes at insertion time. We are tolerant to a reasonable magnitude of out-of-order insertions.
 *
 * At insertion time, we maintain links to useful nodes, rotating them forward as needed to avoid full-scale
 * iteration in either read- or write-modes. These nodes are defined as the _youngest_ node satisfying their
 * category's minimum time threshold.
 */
public class HistoricMetric<T extends Number> {

    // Test Dependency Injection
    private final Clock clock;

    // Metric Sources
    private final Metric<T> numeratorMetric;
    private final Metric<Long> denominatorMetric;

    // Oldest and Newest nodes in linked list
    private final Node origin;
    private final AtomicReference<Node> newest;

    // Important intermediate nodes in our linked list
    private final AtomicReference<Node> quickInstant = new AtomicReference<>();
    private final AtomicReference<Node> quickOneMinute = new AtomicReference<>();
    private final AtomicReference<Node> quickFiveMinutes = new AtomicReference<>();
    private final AtomicReference<Node> quickFifteenMinutes = new AtomicReference<>();

    // Safeguard reads against dead writer
    private final AtomicReference<Instant> lastRecord = new AtomicReference<>();

    public HistoricMetric(Metric<T> numeratorMetric, Metric<Long> denominatorMetric) {
        this(Clock.systemUTC(), numeratorMetric, denominatorMetric);
    }

    public HistoricMetric(Metric<T> metric) {
        this(Clock.systemUTC(), metric);
    }

    HistoricMetric(Clock clock, Metric<T> numeratorMetric, Metric<Long> denominatorMetric) {
        this.clock = clock;
        this.numeratorMetric = numeratorMetric;
        this.denominatorMetric = denominatorMetric;

        // TODO: refactor initial capture out of constructor?
        this.origin = new Node(clock.instant(), numeratorMetric.getValue(), denominatorMetric.getValue());
        this.lastRecord.set(this.origin.timestamp);
        this.newest = new AtomicReference<>(origin);
    }

    HistoricMetric(Clock clock, Metric<T> metric) {
        this(clock, metric, new UptimeMetric(clock));
    }

    // TODO: recording of an HistoricMetric will need to be scheduled
    public void record() {
        record(clock.instant(), numeratorMetric.getValue(), denominatorMetric.getValue());
    }

    void record(final Instant timestamp, final T numerator, final Long denominator) {
        this.newest.getAndUpdate((previousNewest) -> previousNewest.seekAndPrepend(timestamp, numerator, denominator).getNewest());
        this.lastRecord.set(timestamp);

        // rotate our quick references in ascending age order, bailing entirely if we are too young
        if (!rotate(quickInstant, timestamp.minusSeconds(1))) { return; }
        if (!rotate(quickOneMinute, timestamp.minusSeconds(60))) { return; }
        if (!rotate(quickFiveMinutes, timestamp.minusSeconds(300))) { return; }
        if (!rotate(quickFifteenMinutes, timestamp.minusSeconds(900))) { return; }

        // trim out elements that are no longer necessary
        compact();
    }

    // returns true IFF our rotation ended up with a non-null rotation reference
    private boolean rotate(final AtomicReference<Node> rotationReference, final Instant threshold) {
        Node result = rotationReference.updateAndGet((ref) -> Objects.requireNonNullElse(ref, origin).seekAhead(threshold));
        return Objects.nonNull(result);
    }

    private void compact() {
        final Node quick_15 = quickFifteenMinutes.get();
        if (quick_15 != null) {
            origin.nextNode.set(quick_15);
        }
    }

    public Map<String,Double> availableRates() {
        if (lastRecord.get().isBefore(clock.instant().minusSeconds(10))) {
            record();
        }

        final Map<String, Double> rates = new HashMap<>();

        final Double current = rateCurrent();
        if (current != null) {
            rates.put("current", current);
        }
        final Double lastOneMinute = rateLastOneMinute();
        if (lastOneMinute != null) {
            rates.put("last_1_minute", lastOneMinute);
        }
        final Double lastFiveMinutes = rateLastFiveMinutes();
        if (lastFiveMinutes != null) {
            rates.put("last_5_minutes", lastFiveMinutes);
        }
        final Double lastFifteenMinutes = rateLastFifteenMinutes();
        if (lastFifteenMinutes != null) {
            rates.put("last_15_minutes", lastFifteenMinutes);
        }

        final Double lifetime = rateLifetime();
        if (lifetime != null) {
            rates.put("lifetime", lifetime);
        }

        return rates;
    }

    protected Double rateCurrent() {
        return rate(quickInstant);
    }

    protected Double rateLastOneMinute() {
        return rate(quickOneMinute);
    }

    protected Double rateLastFiveMinutes() {
        return rate(quickFiveMinutes);
    }

    protected Double rateLastFifteenMinutes() {
        return rate(quickFifteenMinutes);
    }

    protected Double rateLifetime() {
        return rate(origin);
    }

    private Double rate(final AtomicReference<Node> baselineReference) {
        return rate(baselineReference.get());
    }

    private Double rate(final Node baseline) {
        if (baseline == null) {
            return null;
        } else {
            return newest.get().getRate(baseline);
        }
    }

    private class Node {
        private final AtomicReference<Node> nextNode = new AtomicReference<>();

        private final T numerator;
        private final Long denominator;

        private final Instant timestamp;

        Node(final Instant timestamp, final T numerator, final Long denominator) {
            this.timestamp = timestamp;
            this.numerator = numerator;
            this.denominator = denominator;
        }

        double getRate(final Node baseline) {
            final double deltaNumerator = this.numerator.doubleValue() - baseline.numerator.doubleValue();
            final long deltaDenominator = this.denominator - baseline.denominator;

            return deltaNumerator / deltaDenominator;
        }

        // internal method guarantees we insert at the young end of the singly-linked list, without
        // strict regard to `timestamp` ordering since we are tolerant to minor variations
        // and strict ordering would require us to be doubly-linked.
        Node seekAndPrepend(final Instant timestamp, final T numerator, final Long denominator) {
            return this.nextNode.updateAndGet(oldNextNode -> {
               if (oldNextNode == null) {
                   return new Node(timestamp, numerator, denominator);
               } else {
                   oldNextNode.getNewest().seekAndPrepend(timestamp, numerator, denominator);
                   return oldNextNode;
               }
            });
        }

        Node getNextNode() {
            return nextNode.get();
        }

        // seeks forward until no more nodes can be found
        Node getNewest() {
            Node youngest = this;
            Node candidate = this;

            while (candidate != null) {
                youngest = candidate;
                candidate = candidate.getNextNode();
            }

            return youngest;
        }

        // seeks _forward_ on the timeline, returning the _last_ candidate that is older than the provided threshold.
        // because strict insertion order is not guaranteed, this may return an entry that is _near_ the boundary.
        // returns null if this node is not older than the threshold
        // may return
        Node seekAhead(final Instant threshold) {
            Node youngestEligible = null;
            Node candidate = this;

            while (candidate != null && candidate.timestamp.isBefore(threshold)) {
                youngestEligible = candidate;
                candidate = candidate.getNextNode();
            }

            return youngestEligible;
        }
    }
}
