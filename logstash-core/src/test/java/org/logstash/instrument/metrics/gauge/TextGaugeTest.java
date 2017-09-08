package org.logstash.instrument.metrics.gauge;

import org.junit.Test;
import org.logstash.instrument.metrics.MetricType;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit tests for {@link TextGauge}
 */
public class TextGaugeTest {
    @Test
    public void getValue() {
        TextGauge gauge = new TextGauge("bar", "baz");
        assertThat(gauge.getValue()).isEqualTo("baz");
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_TEXT);

        //Null initialize
        gauge = new TextGauge("bar");
        assertThat(gauge.getValue()).isNull();
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_TEXT);
    }

    @Test
    public void set() {
        TextGauge gauge = new TextGauge("bar");
        gauge.set("baz");
        assertThat(gauge.getValue()).isEqualTo("baz");
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_TEXT);
    }
}
