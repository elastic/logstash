package org.logstash.execution;

import static org.hamcrest.MatcherAssert.assertThat;
import org.jruby.RubyArray;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.junit.Before;
import org.junit.Test;
import org.logstash.Event;
import org.logstash.RubyUtil;
import org.logstash.ackedqueue.QueueFactoryExt;
import org.logstash.ext.JrubyEventExtLibrary;
import org.logstash.instrument.metrics.AbstractNamespacedMetricExt;
import org.logstash.instrument.metrics.MetricKeys;
import org.logstash.instrument.metrics.MockNamespacedMetric;
import org.logstash.instrument.metrics.counter.LongCounter;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.List;

import static org.junit.Assert.assertEquals;

public class QueueReadClientBatchMetricsTest {

    public static final class MockQueueBatch implements QueueBatch {

        private final long processingTimeNanos;
        private final List<JrubyEventExtLibrary.RubyEvent> events;

        public MockQueueBatch(long processingTimeNanos, JrubyEventExtLibrary.RubyEvent... events) {
            this.processingTimeNanos = processingTimeNanos;
            this.events = Arrays.stream(events).toList();
        }

        @Override
        @SuppressWarnings("unchecked")
        public RubyArray<JrubyEventExtLibrary.RubyEvent> to_a() {
            List<IRubyObject> list = new ArrayList<>(events);
            return (RubyArray<JrubyEventExtLibrary.RubyEvent>) RubyUtil.RUBY.newArray(list);
        }

        @Override
        @SuppressWarnings("unchecked")
        public Collection<JrubyEventExtLibrary.RubyEvent> events() {
            return to_a();
        }

        @Override
        public void close() throws IOException {
            // no-op
        }

        @Override
        public int filteredSize() {
            return events.size();
        }

        public long getProcessingTimeNanos() {
            return processingTimeNanos;
        }
    }

    private AbstractNamespacedMetricExt metric;
    private QueueReadClientBatchMetrics sut;
    private LongCounter batchCounter;
    private LongCounter batchByteSizeCounter;
    private JrubyEventExtLibrary.RubyEvent rubyEvent;

    @Before
    public void setUp() {
        metric = MockNamespacedMetric.create();
        sut = new QueueReadClientBatchMetrics(QueueFactoryExt.BatchMetricMode.FULL);
        sut.setupMetrics(metric);

        ThreadContext context = metric.getRuntime().getCurrentContext();
        batchCounter = LongCounter.fromRubyBase(metric.namespace(context, MetricKeys.BATCH_KEY), MetricKeys.BATCH_COUNT);
        batchByteSizeCounter = LongCounter.fromRubyBase(metric.namespace(context, MetricKeys.BATCH_KEY), MetricKeys.BATCH_TOTAL_BYTES);

        rubyEvent = JrubyEventExtLibrary.RubyEvent.newRubyEvent(RubyUtil.RUBY, new Event());
    }

    @Test
    public void givenEmptyBatchAndFullMetricsWhenUpdateBatchMetricsThenNoMetricsAreUpdated() {
        QueueBatch emptyBatch = new MockQueueBatch(10);

        sut.updateBatchMetrics(emptyBatch);

        assertEquals(0L, batchCounter.getValue().longValue());
    }

    @Test
    public void givenNonEmptyBatchAndFullMetricsWhenUpdateBatchMetricsThenMetricsAreUpdated() {
        QueueBatch batch = new MockQueueBatch(10, rubyEvent);
        final long expectedBatchByteSize = rubyEvent.getEvent().estimateMemory();

        sut.updateBatchMetrics(batch);

        assertEquals(1L, batchCounter.getValue().longValue());
        assertEquals(expectedBatchByteSize, batchByteSizeCounter.getValue().longValue());
    }

    @Test
    public void givenNonEmptyBatchesAndMinimalMetricsThenMetricsAreUpdated() {
        sut = new QueueReadClientBatchMetrics(QueueFactoryExt.BatchMetricMode.MINIMAL);
        sut.setupMetrics(metric);

        QueueBatch batch = new MockQueueBatch(10, rubyEvent);
        final long expectedBatchByteSize = rubyEvent.getEvent().estimateMemory();

        // MINIMAL mode has 2% chance per update, so use 500 iterations for ~99.996% probability
        for (int i = 0; i < 500; i++) {
            sut.updateBatchMetrics(batch);
        }

        assertThat(batchCounter.getValue(), org.hamcrest.Matchers.greaterThan(1L));
        assertThat(batchByteSizeCounter.getValue(), org.hamcrest.Matchers.greaterThan(expectedBatchByteSize));
    }

    @Test
    public void givenNonEmptyQueueWhenBatchIsReadAndMetricIsDisabledThenBatchCounterMetricIsNotUpdated() {
        sut = new QueueReadClientBatchMetrics(QueueFactoryExt.BatchMetricMode.DISABLED);
        sut.setupMetrics(metric);
        QueueBatch batch = new MockQueueBatch(10, rubyEvent);

        sut.updateBatchMetrics(batch);

        assertEquals(0L, batchCounter.getValue().longValue());
        assertEquals(0L, batchByteSizeCounter.getValue().longValue());
    }
}