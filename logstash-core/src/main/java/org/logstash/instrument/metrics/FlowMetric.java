package org.logstash.instrument.metrics;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.HashMap;
import java.util.Map;
import java.util.Objects;
import java.util.concurrent.atomic.AtomicReference;

public class FlowMetric extends AbstractMetric<Map<String,Double>> {

    // metric sources
    private final Metric<? extends Number> numeratorMetric;
    private final Metric<? extends Number> denominatorMetric;

    // useful capture nodes for calculation
    private final Capture baseline;

    private final AtomicReference<Capture> head;
    private final AtomicReference<Capture> instant = new AtomicReference<>();

    static final String LIFETIME_KEY = "lifetime";
    static final String CURRENT_KEY = "current";

    public FlowMetric(final String name,
                      final Metric<? extends Number> numeratorMetric,
                      final Metric<? extends Number> denominatorMetric) {
        super(name);
        this.numeratorMetric = numeratorMetric;
        this.denominatorMetric = denominatorMetric;

        this.baseline = doCapture();
        this.head = new AtomicReference<>(this.baseline);
    }

    public void capture() {
        final Capture previousHead = head.getAndSet(doCapture());
        instant.set(previousHead);
    }

    public Map<String,Double> getValue() {
        final Capture headCapture = head.get();
        if (Objects.isNull(headCapture)) {
            return Map.of();
        }

        final Map<String, Double> rates = new HashMap<>();

        final Double lifetimeRate = headCapture.calculateRate(baseline);

        if (Objects.nonNull(lifetimeRate)) {
            rates.put(LIFETIME_KEY, lifetimeRate);
        }

        final Capture instantCapture = instant.get();
        final Double currentRate = headCapture.calculateRate(instantCapture);
        if (Objects.nonNull(currentRate)) {
            rates.put(CURRENT_KEY, currentRate);
        }

        return Map.copyOf(rates);
    }

    Capture doCapture() {
        return new Capture(numeratorMetric.getValue(), denominatorMetric.getValue());
    }

    @Override
    public MetricType getType() {
        return MetricType.FLOW_RATE;
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

            // To prevent the appearance of false-precision, we round to 3 decimal places.
            return BigDecimal.valueOf(deltaNumerator)
                    .divide(BigDecimal.valueOf(deltaDenominator), 3, RoundingMode.HALF_UP)
                    .doubleValue();
        }
    }
}
