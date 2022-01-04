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
import org.assertj.core.data.Percentage;
import org.jruby.RubyHash;
import org.junit.Ignore;
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
    public void testRoot() {
        final NamespacedMetric metrics = this.getInstance().namespace("test");
        final Metric root = metrics.root();
        final NamespacedMetric namespaced = root.namespace("someothernamespace");
        assertThat(namespaced.namespaceName()).containsExactly("someothernamespace");
    }
}
