package org.logstash.instrument.metrics.gauge;

import org.junit.Test;
import org.logstash.instrument.metrics.MetricType;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit tests for {@link DoubleGauge}
 */
public class DoubleGaugeTest {

    @Test
    public void getValue() {
        DoubleGauge gauge = new DoubleGauge("bar", 123.0);
        assertThat(gauge.getValue()).isEqualTo(123.0);
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_DOUBLE);

        //Null
        gauge = new DoubleGauge("bar");
        assertThat(gauge.getValue()).isNull();
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_DOUBLE);
    }

    @Test
    public void set() {
        DoubleGauge gauge = new DoubleGauge("bar");
        assertThat(gauge.getValue()).isNull();
        gauge.set(123.0);
        assertThat(gauge.getValue()).isEqualTo(123.0);
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_DOUBLE);
    }
}