package org.logstash.instrument.metrics.gauge;

import org.junit.Test;
import org.logstash.instrument.metrics.MetricType;

import java.util.Collections;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit tests for {@link BooleanGauge}
 */
public class BooleanGaugeTest {
    @Test
    public void getValue() {
        BooleanGauge gauge = new BooleanGauge(Collections.singletonList("foo"), "bar", true);
        assertThat(gauge.getValue()).isTrue();
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_BOOLEAN);

        //Null initialize
        gauge = new BooleanGauge(Collections.singletonList("foo"), "bar");
        assertThat(gauge.getValue()).isNull();
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_BOOLEAN);
    }

    @Test
    public void set() {
        BooleanGauge gauge = new BooleanGauge(Collections.singletonList("foo"), "bar");
        gauge.set(true);
        assertThat(gauge.getValue()).isTrue();
        gauge.set(false);
        assertThat(gauge.getValue()).isFalse();
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_BOOLEAN);
    }
}