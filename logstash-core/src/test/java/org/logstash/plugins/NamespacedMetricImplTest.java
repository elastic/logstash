package org.logstash.plugins;

import co.elastic.logstash.api.Metric;
import co.elastic.logstash.api.NamespacedMetric;
import org.assertj.core.data.Percentage;
import org.jruby.RubyHash;
import org.junit.Test;

import static org.assertj.core.api.Assertions.assertThat;

public class NamespacedMetricImplTest extends MetricTestCase {
    @Test
    public void testGauge() {
        final NamespacedMetric metrics = this.getInstance().namespace("test");

        metrics.gauge("abc", "def");
        {
            final RubyHash metricStore = getMetricStore(new String[]{"test"});
            assertThat(this.getMetricStringValue(metricStore, "abc")).isEqualTo("def");
        }

        metrics.gauge("abc", "123");
        {
            final RubyHash metricStore = getMetricStore(new String[]{"test"});
            assertThat(this.getMetricStringValue(metricStore, "abc")).isEqualTo("123");
        }
    }

    @Test
    public void testIncrement() {
        final NamespacedMetric metrics = this.getInstance().namespace("test");

        metrics.increment("abc");
        {
            final RubyHash metricStore = getMetricStore(new String[]{"test"});
            assertThat(this.getMetricLongValue(metricStore, "abc")).isEqualTo(1);
        }

        metrics.increment("abc");
        {
            final RubyHash metricStore = getMetricStore(new String[]{"test"});
            assertThat(this.getMetricLongValue(metricStore, "abc")).isEqualTo(2);
        }
    }

    @Test
    public void testIncrementWithAmount() {
        final NamespacedMetric metrics = this.getInstance().namespace("test");

        metrics.increment("abc", 2);
        {
            final RubyHash metricStore = getMetricStore(new String[]{"test"});
            assertThat(this.getMetricLongValue(metricStore, "abc")).isEqualTo(2);
        }

        metrics.increment("abc", 3);
        {
            final RubyHash metricStore = getMetricStore(new String[]{"test"});
            assertThat(this.getMetricLongValue(metricStore, "abc")).isEqualTo(5);
        }
    }

    @Test
    public void testTimeCallable() {
        final NamespacedMetric metrics = this.getInstance().namespace("test");
        metrics.time("abc", () -> {
            try {
                Thread.sleep(100);
            } catch (InterruptedException e) {
                throw new RuntimeException(e);
            }
            return null;
        });
        final RubyHash metricStore = getMetricStore(new String[]{"test"});
        assertThat(this.getMetricLongValue(metricStore, "abc")).isCloseTo(100, Percentage.withPercentage(5));
    }

    @Test
    public void testReportTime() {
        final NamespacedMetric metrics = this.getInstance().namespace("test");

        metrics.reportTime("abc", 123);
        {
            final RubyHash metricStore = getMetricStore(new String[]{"test"});
            assertThat(this.getMetricLongValue(metricStore, "abc")).isEqualTo(123);
        }

        metrics.reportTime("abc", 877);
        {
            final RubyHash metricStore = getMetricStore(new String[]{"test"});
            assertThat(this.getMetricLongValue(metricStore, "abc")).isEqualTo(1000);
        }
    }

    @Test
    public void testNamespace() {
        final NamespacedMetric metrics = this.getInstance().namespace("test");

        final NamespacedMetric namespaced = metrics.namespace("abcdef");
        assertThat(namespaced.namespaceName()).containsExactly("test", "abcdef");

        final NamespacedMetric namespaced2 = namespaced.namespace("12345", "qwerty");
        assertThat(namespaced2.namespaceName()).containsExactly("test", "abcdef", "12345", "qwerty");
    }

    @Test
    public void testRoot() {
        final NamespacedMetric metrics = this.getInstance().namespace("test");
        final Metric root = metrics.root();
        final NamespacedMetric namespaced = root.namespace("someothernamespace");
        assertThat(namespaced.namespaceName()).containsExactly("someothernamespace");
    }
}
