/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *	http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */


package org.logstash.plugins;

import co.elastic.logstash.api.Metric;
import co.elastic.logstash.api.NamespacedMetric;
import co.elastic.logstash.api.UserMetric;
import org.assertj.core.data.Percentage;
import org.jruby.RubyHash;
import org.junit.Ignore;
import org.junit.Test;
import org.logstash.instrument.metrics.MetricType;

import java.util.Arrays;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;

public class NamespacedMetricImplTest extends MetricTestCase {
    @Test
    public void testGauge() {
        doTestGauge("test");
    }
    @Test
    public void testGaugeNested() {
        doTestGauge("test", "deep");
    }

    @Test
    public void testGaugeUnicode() {
        doTestGauge("test", "Ümlãut-åccênt", "okay");
    }

    public void doTestGauge(final String... metricNamespace) {
        final NamespacedMetric metrics = this.getInstance().namespace(metricNamespace);

        metrics.gauge("abc", "def");
        {
            final RubyHash metricStore = getMetricStore(Arrays.copyOf(metricNamespace, metricNamespace.length));
            assertThat(this.getMetricStringValue(metricStore, "abc")).isEqualTo("def");
        }

        metrics.gauge("abc", "123");
        {
            final RubyHash metricStore = getMetricStore(Arrays.copyOf(metricNamespace, metricNamespace.length));
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

    @Ignore("Test failing intermittently for some time. See https://github.com/elastic/logstash/issues/11925")
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
    public void testNamespaceUnicodeFragment() {
        final NamespacedMetric metrics = this.getInstance().namespace("test", "Ünîcødé", "nÉs†iñG");

        final NamespacedMetric namespaced = metrics.namespace("abcdef");
        assertThat(namespaced.namespaceName()).containsExactly("test", "Ünîcødé", "nÉs†iñG", "abcdef");

        final NamespacedMetric namespaced2 = namespaced.namespace("12345", "qwerty");
        assertThat(namespaced2.namespaceName()).containsExactly("test", "Ünîcødé", "nÉs†iñG", "abcdef", "12345", "qwerty");
    }

    @Test
    public void testRoot() {
        final NamespacedMetric metrics = this.getInstance().namespace("test");
        final Metric root = metrics.root();
        final NamespacedMetric namespaced = root.namespace("someothernamespace");
        assertThat(namespaced.namespaceName()).containsExactly("someothernamespace");
    }

    @Test
    public void testRegister() {
        final NamespacedMetric metrics = this.getInstance().namespace("testRegister");

        CustomMetric leftCustomMetric = metrics.register("left", CorrelatingCustomMetric.FACTORY);

        // re-registering the same metric should get the existing instance.
        assertThat(metrics.register("left", CorrelatingCustomMetric.FACTORY)).isSameAs(leftCustomMetric);

        // registering a new metric should be different instance
        CustomMetric rightCustomMetric = metrics.register("right", CorrelatingCustomMetric.FACTORY);
        assertThat(rightCustomMetric).isNotSameAs(leftCustomMetric);

        // this tests our test-only CustomMetric impl more than anything, but it validates
        // that the instances we update are connected to their values.
        leftCustomMetric.record("this");
        leftCustomMetric.record("that");
        rightCustomMetric.record("that");
        leftCustomMetric.record("this");
        rightCustomMetric.record("another");
        rightCustomMetric.record("that");
        rightCustomMetric.record("another");

        assertThat(leftCustomMetric.getValue()).contains("this=2", "that=1");
        assertThat(rightCustomMetric.getValue()).contains("that=2", "another=2");
    }

    private interface CustomMetric extends UserMetric<String>, org.logstash.instrument.metrics.Metric<String> {
        void record(final String value);

        UserMetric.Provider<CustomMetric> PROVIDER = new UserMetric.Provider<CustomMetric>(CustomMetric.class, new CustomMetric() {
            @Override
            public void record(String value) {
                // no-op
            }

            @Override
            public String getName() {
                return "CustomMetric";
            }

            @Override
            public MetricType getType() {
                return MetricType.USER;
            }

            @Override
            public String getValue() {
                return "";
            }
        });
    }

    private static class CorrelatingCustomMetric implements CustomMetric {
        private final ConcurrentHashMap<String, Integer> mapping = new ConcurrentHashMap<>();

        static UserMetric.Factory<CustomMetric> FACTORY = CustomMetric.PROVIDER.getFactory((name) -> new CorrelatingCustomMetric());

        @Override
        public void record(String value) {
            mapping.compute(value, (k, v) -> v == null ? 1 : v + 1);
        }

        @Override
        public String getName() {
            return "CorrelatingCustomMetric";
        }

        @Override
        public MetricType getType() {
            return MetricType.USER;
        }

        @Override
        public String getValue() {
            return Map.copyOf(mapping).entrySet()
                    .stream()
                    .sorted(Map.Entry.comparingByKey())
                    .map((e) -> (e.getKey() + '=' + e.getValue().toString()))
                    .reduce((a, b) -> a + ';' + b).orElse("EMPTY");
        }
    }
}
