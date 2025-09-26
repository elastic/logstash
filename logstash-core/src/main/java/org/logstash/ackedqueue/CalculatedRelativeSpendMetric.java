package org.logstash.ackedqueue;

import org.logstash.instrument.metrics.AbstractMetric;
import org.logstash.instrument.metrics.UptimeMetric;
import org.logstash.instrument.metrics.timer.TimerMetric;
import org.logstash.instrument.metrics.timer.TimerMetricFactory;

import java.math.BigDecimal;
import java.math.MathContext;
import java.math.RoundingMode;

class CalculatedRelativeSpendMetric extends AbstractMetric<Double> implements RelativeSpendMetric {
    private static final MathContext LIMITED_PRECISION = new MathContext(4, RoundingMode.HALF_UP);

    private final TimerMetric spendMetric;
    private final UptimeMetric uptimeMetric;

    public static Factory<RelativeSpendMetric> FACTORY = RelativeSpendMetric.PROVIDER.getFactory(CalculatedRelativeSpendMetric::new);

    public CalculatedRelativeSpendMetric(final String name) {
        this(name, TimerMetricFactory.getInstance().create(name + ":spend"), new UptimeMetric(name + ":uptime"));
    }

    CalculatedRelativeSpendMetric(String name, TimerMetric spendMetric, UptimeMetric uptimeMetric) {
        super(name);
        this.spendMetric = spendMetric;
        this.uptimeMetric = uptimeMetric;
    }

    @Override
    public <T, E extends Throwable> T time(ExceptionalSupplier<T, E> exceptionalSupplier) throws E {
        return this.spendMetric.time(exceptionalSupplier);
    }

    @Override
    public void reportUntrackedMillis(long untrackedMillis) {
        this.spendMetric.reportUntrackedMillis(untrackedMillis);
    }

    @Override
    public Double getValue() {
        BigDecimal spend = BigDecimal.valueOf(spendMetric.getValue());
        BigDecimal uptime = BigDecimal.valueOf(uptimeMetric.getValue());

        if (uptime.signum() == 0) {
            switch (spend.signum()) {
                case -1:
                    return Double.NEGATIVE_INFINITY;
                case 0:
                    return 0.0;
                case +1:
                    return Double.POSITIVE_INFINITY;
            }
        }

        return spend.divide(uptime, LIMITED_PRECISION).doubleValue();
    }
}
