package org.logstash.instrument.metrics.gauge;

import org.junit.Test;
import org.logstash.instrument.metrics.MetricType;

import java.net.URI;
import java.util.Collections;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit tests for {@link UnknownGauge}
 */
public class UnknownGaugeTest {

    @Test
    public void getValue() {
        UnknownGauge gauge = new UnknownGauge("bar", URI.create("baz"));
        assertThat(gauge.isDirty()).isTrue();
        assertThat(gauge.getValue()).isEqualTo(URI.create("baz"));
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_UNKNOWN);

        //Null initialize
        gauge = new UnknownGauge("bar");
        assertThat(gauge.getValue()).isNull();
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_UNKNOWN);
    }

    @Test
    public void set() {
        UnknownGauge gauge = new UnknownGauge("bar");
        assertThat(gauge.isDirty()).isFalse();
        gauge.set(URI.create("baz"));
        assertThat(gauge.getValue()).isEqualTo(URI.create("baz"));
        gauge.set(URI.create("fizzbuzz"));
        assertThat(gauge.getValue()).isEqualTo(URI.create("fizzbuzz"));
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_UNKNOWN);
        assertThat(gauge.isDirty()).isTrue();
        gauge.setDirty(false);
        assertThat(gauge.isDirty()).isFalse();
    }
}
