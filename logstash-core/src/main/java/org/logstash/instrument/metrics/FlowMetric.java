package org.logstash.instrument.metrics;

import java.util.HashMap;
import java.util.Map;
import java.util.Objects;
import java.util.concurrent.atomic.AtomicReference;

public class FlowMetric {

    // metric sources
    private final Metric<? extends Number> numeratorMetric;
    private final Metric<? extends Number> denominatorMetric;

    // useful capture nodes for calculation
    private final Capture baseline;

    private final AtomicReference<Capture> head;
    private final AtomicReference<Capture> instant = new AtomicReference<>();

    public FlowMetric(final Metric<? extends Number> numeratorMetric, final Metric<? extends Number> denominatorMetric) {
        this.numeratorMetric = numeratorMetric;
        this.denominatorMetric = denominatorMetric;

        this.baseline = doCapture();
        this.head = new AtomicReference<>(this.baseline);
    }

    public void capture() {
        final Capture previousHead = head.getAndSet(doCapture());
        instant.set(previousHead);
    }

    public Map<String,Double> getAvailableRates() {
        final Capture headCapture = head.get();
        if (Objects.isNull(headCapture)) {
            return Map.of();
        }

        final Map<String, Double> rates = new HashMap<>();

        final Double lifetimeRate = headCapture.calculateRate(baseline);
        if (Objects.nonNull(lifetimeRate)) {
            rates.put("lifetime", lifetimeRate);
        }

        final Capture instantCapture = instant.get();
        final Double currentRate = headCapture.calculateRate(instantCapture);
        if (Objects.nonNull(currentRate)) {
            rates.put("current", currentRate);
        }

        return Map.copyOf(rates);
    }

    Capture doCapture() {
        return new Capture(numeratorMetric.getValue(), denominatorMetric.getValue());
    }

    private static class Capture {
        private final Number numerator;
        private final Number denominator;

        public Capture(final Number numerator, final Number denominator) {
            this.numerator = numerator;
            this.denominator = denominator;
        }

        Double calculateRate(final Capture baseline) {
            if (Objects.isNull(baseline)) { return null; }
            if (baseline == this) { return null; }

            final double deltaNumerator = this.numerator.doubleValue() - baseline.numerator.doubleValue();
            final double deltaDenominator = this.denominator.doubleValue() - baseline.denominator.doubleValue();

            return deltaNumerator / deltaDenominator;
        }
    }
}