package org.logstash.instrument.metrics.gauge;

import org.junit.Test;
import org.logstash.instrument.metrics.MetricType;

import java.math.BigInteger;
import java.util.Collections;

import static org.assertj.core.api.Assertions.assertThat;


/**
 * Unit tests for {@link NumericGauge}
 */
public class NumericGaugeTest {


    @Test
    public void getValue() {

        //Long
        NumericGauge gauge = new NumericGauge(Collections.singletonList("foo"), "bar", 99l);
        assertThat(gauge.getValue()).isEqualTo(99l);
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_NUMERIC);

        //Float
        gauge = new NumericGauge(Collections.singletonList("foo"), "bar", 123.0f);
        assertThat(gauge.getValue()).isEqualTo(123.0f);
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_NUMERIC);

        //Null
        gauge = new NumericGauge(Collections.singletonList("foo"), "bar");
        assertThat(gauge.getValue()).isNull();
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_NUMERIC);
    }


    @Test
    public void set() {
        //Long
        NumericGauge gauge = new NumericGauge(Collections.singletonList("foo"), "bar");
        gauge.set(99l);
        assertThat(gauge.getValue()).isEqualTo(99l);
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_NUMERIC);

        //Float
        gauge = new NumericGauge(Collections.singletonList("foo"), "bar");
        gauge.set(123.0f);
        assertThat(gauge.getValue()).isEqualTo(123.0f);
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_NUMERIC);

        //Null
        gauge = new NumericGauge(Collections.singletonList("foo"), "bar");
        gauge.set(BigInteger.TEN);
        assertThat(gauge.getValue()).isEqualTo(BigInteger.TEN);
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_NUMERIC);
    }
}