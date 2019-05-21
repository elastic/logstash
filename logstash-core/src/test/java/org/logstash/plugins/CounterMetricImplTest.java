package org.logstash.plugins;

import co.elastic.logstash.api.CounterMetric;
import co.elastic.logstash.api.NamespacedMetric;
import org.junit.Test;

import static org.assertj.core.api.Assertions.assertThat;

public class CounterMetricImplTest extends MetricTestCase {
    @Test
    public void testIncrement() {
        final NamespacedMetric namespace = this.getInstance().namespace("ayo");
        final CounterMetric metric = namespace.counter("abcdef");
        metric.increment();
        assertThat(metric.getValue()).isEqualTo(1);
        assertThat(getMetricLongValue(getMetricStore(new String[]{"ayo"}), "abcdef")).isEqualTo(1);
    }

    @Test
    public void testIncrementByAmount() {
        final NamespacedMetric namespace = this.getInstance().namespace("ayo");
        final CounterMetric metric = namespace.counter("abcdef");
        metric.increment(5);
        assertThat(metric.getValue()).isEqualTo(5);
        assertThat(getMetricLongValue(getMetricStore(new String[]{"ayo"}), "abcdef")).isEqualTo(5);
    }

    @Test
    public void testReset() {
        final NamespacedMetric namespace = this.getInstance().namespace("ayo");
        final CounterMetric metric = namespace.counter("abcdef");

        metric.increment(1);
        assertThat(metric.getValue()).isEqualTo(1);
        assertThat(getMetricLongValue(getMetricStore(new String[]{"ayo"}), "abcdef")).isEqualTo(1);

        metric.reset();
        assertThat(metric.getValue()).isEqualTo(0);
        assertThat(getMetricLongValue(getMetricStore(new String[]{"ayo"}), "abcdef")).isEqualTo(0);
    }
}
