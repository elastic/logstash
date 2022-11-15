package org.logstash.instrument.metrics;

import java.math.BigDecimal;

import static org.logstash.instrument.metrics.MetricType.GAUGE_NUMBER;

/**
 * A scaled metric to apply given scale at metric get value.
 */
public class UpScaledMetric extends AbstractMetric<BigDecimal> implements Metric<BigDecimal> {

    private final Metric<? extends Number> metric;

    private final BigDecimal scaleFactor;

    public UpScaledMetric(final String name,
                          final Metric<? extends Number> metric,
                          final int scaleFactor) {
        super(name);
        this.metric = metric;
        this.scaleFactor = BigDecimal.valueOf(scaleFactor);
    }

    public UpScaledMetric(final Metric<? extends Number> metric,
                          final int scaleFactor) {
        this(String.format("%s_x%s", metric.getName(), scaleFactor), metric, scaleFactor);
    }

    @Override
    public MetricType getType() {
        return GAUGE_NUMBER;
    }

    @Override
    public BigDecimal getValue() {
        final Number unscaledValue = this.metric.getValue();
        final BigDecimal scaledValue = convertToBigDecimal(unscaledValue).multiply(scaleFactor);
        return scaledValue;
    }

    private static BigDecimal convertToBigDecimal(Number number) {
        if (number instanceof BigDecimal) { return (BigDecimal) number; }
        if (number instanceof Integer
                || number instanceof Long
                || number instanceof Short
                || number instanceof Byte) {
            return BigDecimal.valueOf(number.longValue());
        }
        return BigDecimal.valueOf(number.doubleValue());
    }
}