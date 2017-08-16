package org.logstash.instrument.metrics.gauge;

import org.junit.Test;
import org.logstash.instrument.metrics.MetricType;

import static org.assertj.core.api.Assertions.assertThat;


/**
 * Unit tests for {@link LongGauge}
 */
public class LongGaugeTest {

    @Test
    public void getValue() {
        LongGauge gauge = new LongGauge("bar", 99l);
        assertThat(gauge.getValue()).isEqualTo(99);
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_LONG);

        //Null
        gauge = new LongGauge("bar");
        assertThat(gauge.getValue()).isNull();
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_LONG);
    }

    @Test
    public void set() {
        LongGauge gauge = new LongGauge("bar");
        assertThat(gauge.getValue()).isNull();
        gauge.set(123l);
        assertThat(gauge.getValue()).isEqualTo(123);
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_LONG);
    }
}