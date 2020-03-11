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
