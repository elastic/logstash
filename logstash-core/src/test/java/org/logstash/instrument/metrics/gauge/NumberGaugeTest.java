package org.logstash.instrument.metrics.gauge;

import org.junit.Test;
import org.logstash.instrument.metrics.MetricType;

import static org.assertj.core.api.Assertions.assertThat;


/**
 * Unit tests for {@link NumberGauge}
 */
public class NumberGaugeTest {

    @Test
    public void getValue() {
        NumberGauge gauge = new NumberGauge("bar", 99l);
        assertThat(gauge.getValue()).isEqualTo(99l);
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_NUMBER);
        //other number type
        gauge.set(98.00);
        assertThat(gauge.getValue()).isEqualTo(98.00);

        //Null
        gauge = new NumberGauge("bar");
        assertThat(gauge.getValue()).isNull();
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_NUMBER);
    }

    @Test
    public void set() {
        NumberGauge gauge = new NumberGauge("bar");
        assertThat(gauge.getValue()).isNull();
        gauge.set(123l);
        assertThat(gauge.getValue()).isEqualTo(123l);
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_NUMBER);
    }
}