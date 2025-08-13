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


package org.logstash.ext;

import java.io.IOException;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.BlockingQueue;
import org.jruby.RubyHash;
import org.jruby.runtime.ThreadContext;
import org.junit.Test;
import org.logstash.Event;
import org.logstash.RubyTestBase;
import org.logstash.RubyUtil;
import org.logstash.execution.QueueBatch;
import org.logstash.instrument.metrics.AbstractNamespacedMetricExt;
import org.logstash.instrument.metrics.MetricKeys;
import org.logstash.instrument.metrics.MockNamespacedMetric;
import org.logstash.instrument.metrics.histogram.HistogramMetric;
import org.logstash.instrument.metrics.histogram.HistogramSnapshot;

import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.junit.Assert.assertEquals;

/**
 * Tests for {@link JrubyMemoryReadClientExt}.
 */
public final class JrubyMemoryReadClientExtTest extends RubyTestBase {

    @Test
    @SuppressWarnings("deprecation")
    public void testInflightBatchesTracking() throws InterruptedException, IOException {
        final BlockingQueue<JrubyEventExtLibrary.RubyEvent> queue = new ArrayBlockingQueue<>(10);
        final JrubyMemoryReadClientExt client = JrubyMemoryReadClientExt.create(queue, 5, 50);

        final ThreadContext context = client.getRuntime().getCurrentContext();

        AbstractNamespacedMetricExt metric = MockNamespacedMetric.create();
        client.setPipelineMetric(metric);

        final QueueBatch batch = client.readBatch();
        final RubyHash inflight = client.rubyGetInflightBatches(context);
        assertThat(inflight.size(), is(1));
        // JTODO getId has been deprecated in JDK 19, when JDK 21 is the target version use threadId() instead
        assertThat(inflight.get(Thread.currentThread().getId()), is(batch));
        client.closeBatch(batch);
        assertThat(client.rubyGetInflightBatches(context).size(), is(0));
    }

    @Test
    public void givenNonEmptyQueueAndEnabledBatchSizeMetricThenHistogramContainsData() throws InterruptedException {
        final JrubyEventExtLibrary.RubyEvent testEvent = JrubyEventExtLibrary.RubyEvent.newRubyEvent(RubyUtil.RUBY, new Event());
        final BlockingQueue<JrubyEventExtLibrary.RubyEvent> queue = new ArrayBlockingQueue<>(10);
        queue.add(testEvent);

        final JrubyMemoryReadClientExt client = JrubyMemoryReadClientExt.create(queue, 5, 50);

        AbstractNamespacedMetricExt metric = MockNamespacedMetric.create();
        client.setPipelineMetric(metric);

        final QueueBatch batch = client.readBatch();
        assertEquals(1, batch.filteredSize());

        HistogramMetric histogram = HistogramMetric.fromRubyBase(metric, MetricKeys.BATCH_SIZE_KEY);
        HistogramSnapshot metricSnapshot = histogram.getValue();
        assertEquals(1.0, metricSnapshot.get75Percentile(), 0.0001);
        assertEquals(1.0, metricSnapshot.get90Percentile(), 0.0001);
    }
}
