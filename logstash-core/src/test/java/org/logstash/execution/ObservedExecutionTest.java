package org.logstash.execution;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.runtime.ThreadContext;
import org.junit.Test;
import org.logstash.config.ir.CompiledPipeline;
import org.logstash.config.ir.RubyEnvTestCase;
import org.logstash.ext.JrubyEventExtLibrary;
import org.logstash.instrument.metrics.AbstractNamespacedMetricExt;
import org.logstash.instrument.metrics.ManualAdvanceClock;
import org.logstash.instrument.metrics.MetricExt;
import org.logstash.instrument.metrics.MetricExtFactory;
import org.logstash.instrument.metrics.MetricKeys;
import org.logstash.instrument.metrics.counter.LongCounter;
import org.logstash.instrument.metrics.timer.TimerMetric;

import java.io.IOException;
import java.time.Duration;
import java.time.Instant;
import java.util.Arrays;
import java.util.Collection;
import java.util.stream.Collectors;

import static org.hamcrest.Matchers.*;
import static org.junit.Assert.*;

public class ObservedExecutionTest extends RubyEnvTestCase {

    /**
     * This test emulates events flowing through multiple workers in two pipelines to ensure
     * that our {@link ObservedExecution} correctly records event counts for filtered and output,
     * along with the timing of execution.
     */
    @Test
    public void compute() throws IOException {
        final ManualAdvanceClock manualAdvanceClock = new ManualAdvanceClock(Instant.now());
        final MetricExt rootMetric = MetricExtFactory.newMetricExtFromTestClock(manualAdvanceClock);
        final MockCompiledExecution mockQueueBatchExecution = new MockCompiledExecution(manualAdvanceClock);

        final AbstractNamespacedMetricExt processEventsNamespace = namespaceMetric(rootMetric, "events");
        final AbstractNamespacedMetricExt pipelineAEventsNamespace = namespaceMetric(rootMetric, "pipelines", "a", "events");
        final AbstractNamespacedMetricExt pipelineBEventsNamespace = namespaceMetric(rootMetric, "pipelines", "b", "events");

        // we create two worker observers, one for each pipeline, connected to the relevant metric namespaces
        final WorkerObserver pipelineAWorkerObserver = new WorkerObserver(processEventsNamespace, pipelineAEventsNamespace);
        final WorkerObserver pipelineBWorkerObserver = new WorkerObserver(processEventsNamespace, pipelineBEventsNamespace);

        // we create three observed executions to test, one for pipeline A, and two for pipeline B
        final ObservedExecution<MockQueueBatch> executionPipelineAWorker1 = pipelineAWorkerObserver.ofExecution(mockQueueBatchExecution);
        final ObservedExecution<MockQueueBatch> executionPipelineBWorker1 = pipelineBWorkerObserver.ofExecution(mockQueueBatchExecution);
        final ObservedExecution<MockQueueBatch> executionPipelineBWorker2 = pipelineBWorkerObserver.ofExecution(mockQueueBatchExecution);

        // in pipeline A, we take 110.9ms to filter 100 events and output 10 events
        final MockQueueBatch mockQueueBatchA = new MockQueueBatch(100, 10, 110_900_000L);
        final int eventsOutputA = executionPipelineAWorker1.compute(mockQueueBatchA, false, false);
        assertThat(eventsOutputA, is(equalTo(10)));

        // in pipeline B on worker 1, we take 1010.9ms to filter 1000 events and output 100 events
        final MockQueueBatch mockQueueBatchB = new MockQueueBatch(1000, 100, 1_010_900_000L);
        final int eventsOutputB = executionPipelineBWorker1.compute(mockQueueBatchB, false, false);
        assertThat(eventsOutputB, is(equalTo(100)));

        // again in pipeline B on worker 1, we take 10010.9ms to filter 1000 events and output 1000 events
        final MockQueueBatch mockQueueBatchB2 = new MockQueueBatch(1000, 1000, 10_010_900_000L);
        final int eventsOutputB2 = executionPipelineBWorker1.compute(mockQueueBatchB2, false, false);
        assertThat(eventsOutputB2, is(equalTo(1000)));

        // and in pipeline B on worker 2, we take 100010.9ms to filter 1000 events and output 10000 events
        final MockQueueBatch mockQueueBatchB3 = new MockQueueBatch(1000, 10000, 100_010_900_000L);
        final int eventsOutputB3 = executionPipelineBWorker2.compute(mockQueueBatchB3, false, false);
        assertThat(eventsOutputB3, is(equalTo(10000)));

        // validate that the inbound filter counts made it to our independent pipeline metrics and to the combined process
        final LongCounter pipelineAEventsFilteredCounter = LongCounter.fromRubyBase(pipelineAEventsNamespace, MetricKeys.FILTERED_KEY);
        final LongCounter pipelineBEventsFilteredCounter = LongCounter.fromRubyBase(pipelineBEventsNamespace, MetricKeys.FILTERED_KEY);
        final LongCounter processEventsFilteredCounter = LongCounter.fromRubyBase(processEventsNamespace, MetricKeys.FILTERED_KEY);
        assertThat(pipelineAEventsFilteredCounter.getValue(), is(equalTo(100L)));
        assertThat(pipelineBEventsFilteredCounter.getValue(), is(equalTo(3000L)));
        assertThat(processEventsFilteredCounter.getValue(), is(equalTo(3100L)));

        // validate that the outbound execution counts made it to our independent pipeline metrics and to the combined process
        final LongCounter pipelineAEventsOutCounter = LongCounter.fromRubyBase(pipelineAEventsNamespace, MetricKeys.OUT_KEY);
        final LongCounter pipelineBEventsOutCounter = LongCounter.fromRubyBase(pipelineBEventsNamespace, MetricKeys.OUT_KEY);
        final LongCounter processEventsOutCounter = LongCounter.fromRubyBase(processEventsNamespace, MetricKeys.OUT_KEY);
        assertThat(pipelineAEventsOutCounter.getValue(), is(equalTo(10L)));
        assertThat(pipelineBEventsOutCounter.getValue(), is(equalTo(11100L)));
        assertThat(processEventsOutCounter.getValue(), is(equalTo(11110L)));

        // validate that the timings were reported to our independent pipeline metrics and to the combined process
        final TimerMetric pipelineADurationTimer = TimerMetric.fromRubyBase(pipelineAEventsNamespace, MetricKeys.DURATION_IN_MILLIS_KEY);
        final TimerMetric pipelineBDurationTimer = TimerMetric.fromRubyBase(pipelineBEventsNamespace, MetricKeys.DURATION_IN_MILLIS_KEY);
        final TimerMetric processDurationTimer = TimerMetric.fromRubyBase(processEventsNamespace, MetricKeys.DURATION_IN_MILLIS_KEY);
        assertThat(pipelineADurationTimer.getValue(), is(equalTo(110L)));    // 110.9 -> 110
        assertThat(pipelineBDurationTimer.getValue(), is(equalTo(111032L))); // 1010.9 + 10010.9 + 100010.9 = 111032.7 -> 111032
        assertThat(processDurationTimer.getValue(), is(equalTo(111143L)));   // 110.9 + 101.9 + 1001.9 + 10001.9 = 111143.6 -> 111143
    }

    private AbstractNamespacedMetricExt namespaceMetric(final MetricExt metricExt, final String... namespaces) {
        final Ruby runtime = metricExt.getRuntime();
        final ThreadContext context = runtime.getCurrentContext();

        return metricExt.namespace(context, runtime.newArray(Arrays.stream(namespaces).map(runtime::newSymbol).collect(Collectors.toList())));
    }

    /**
     * This {@code MockCompiledExecution} is an implementation of {@link CompiledPipeline.Execution}
     * whose behaviour for {@code compute} is determined by the {@link MockQueueBatch} it receives.
     * it is instantiated with a {@link ManualAdvanceClock}, which it advances during execution by
     * {@code MockQueueBatch.executionDurationNanos}, and each computation returns the provided
     * {@code MockQueueBatch.computationOutputSize} as its result.
     */
    static class MockCompiledExecution implements CompiledPipeline.Execution<MockQueueBatch> {
        private final ManualAdvanceClock manualAdvanceClock;

        public MockCompiledExecution(final ManualAdvanceClock manualAdvanceClock) {
            this.manualAdvanceClock = manualAdvanceClock;
        }

        @Override
        public int compute(MockQueueBatch batch, boolean flush, boolean shutdown) {
            this.manualAdvanceClock.advance(Duration.ofNanos(batch.executionDurationNanos));
            return batch.computationOutputSize;
        }
    }

    /**
     * A minimal implementation of {@code QueueBatch} exclusively for use with {@link MockCompiledExecution}
     * and providing the minimum subset of {@code QueueBatch}'s interface to satisfy {@link ObservedExecution<MockQueueBatch>}.
     */
    static class MockQueueBatch implements QueueBatch {
        private final int initialSize;
        private final int computationOutputSize;

        private final long executionDurationNanos;

        public MockQueueBatch(int initialSize, int computationOutputSize, long executionDurationNanos) {
            this.initialSize = initialSize;
            this.computationOutputSize = computationOutputSize;
            this.executionDurationNanos = executionDurationNanos;
        }

        @Override
        public int filteredSize() {
            return this.initialSize;
        }

        @Override
        public RubyArray<JrubyEventExtLibrary.RubyEvent> to_a() {
            throw new IllegalStateException("Mock Batch `to_a` method is not defined.");
        }

        @Override
        public Collection<JrubyEventExtLibrary.RubyEvent> events() {
            throw new IllegalStateException("Mock Batch `events` method is not defined.");
        }
        @Override
        public void close() throws IOException {
            // no-op
        }

    }
}