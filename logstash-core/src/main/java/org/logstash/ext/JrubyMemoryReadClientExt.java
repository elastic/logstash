package org.logstash.ext;

import org.jruby.Ruby;
import org.jruby.RubyBasicObject;
import org.jruby.RubyClass;
import org.jruby.RubyHash;
import org.jruby.RubyNumeric;
import org.jruby.RubyObject;
import org.jruby.RubySymbol;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.java.proxies.JavaProxy;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.common.LsQueueUtils;
import org.logstash.instrument.metrics.counter.LongCounter;

import java.util.concurrent.BlockingQueue;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.TimeUnit;

@JRubyClass(name = "MemoryReadClient")
public class JrubyMemoryReadClientExt extends RubyObject {

    private static final RubySymbol OUT_KEY = RubyUtil.RUBY.newSymbol("out");
    private static final RubySymbol FILTERED_KEY = RubyUtil.RUBY.newSymbol("filtered");
    private static final RubySymbol DURATION_IN_MILLIS_KEY =
            RubyUtil.RUBY.newSymbol("duration_in_millis");

    private BlockingQueue queue;
    private ConcurrentHashMap<Long, IRubyObject> inflightBatches;
    private ConcurrentHashMap<Long, Long> inflightClocks;
    private int batchSize;
    private long waitForNanos;
    private LongCounter eventMetricOut;
    private LongCounter eventMetricFiltered;
    private LongCounter eventMetricTime;
    private LongCounter pipelineMetricOut;
    private LongCounter pipelineMetricFiltered;
    private LongCounter pipelineMetricTime;

    public JrubyMemoryReadClientExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @JRubyMethod(name = "initialize")
    @SuppressWarnings("unchecked")
    public void rubyInitialize(final ThreadContext context, IRubyObject queue,
                               IRubyObject batchSize, IRubyObject waitForMillis) {
        this.queue = (BlockingQueue) (((JavaProxy) queue).getObject());

        // Note that @inflight_batches as a central mechanism for tracking inflight
        // batches will fail if we have multiple read clients in the pipeline.
        inflightBatches = new ConcurrentHashMap<>();

        // allow the worker thread to report the execution time of the filter + output
        inflightClocks = new ConcurrentHashMap<>();
        this.batchSize = ((RubyNumeric) batchSize).getIntValue();
        waitForNanos = TimeUnit.NANOSECONDS.convert(
                ((RubyNumeric) waitForMillis).getIntValue(), TimeUnit.MILLISECONDS);
    }

    @JRubyMethod(name = "close")
    public void rubyClose(final ThreadContext context) {
        // noop, for compatibility with acked queue read client
    }

    public boolean isEmpty() {
        return queue.isEmpty();
    }

    @JRubyMethod(name = "empty?")
    public IRubyObject rubyIsEmpty(final ThreadContext context) {
        return context.runtime.newBoolean(isEmpty());
    }

    public void setBatchDimensions(int batchSize, int waitForMillis) {
        this.batchSize = batchSize;
        waitForNanos = TimeUnit.NANOSECONDS.convert(waitForMillis, TimeUnit.MILLISECONDS);
    }

    @JRubyMethod(name = "set_batch_dimensions")
    public IRubyObject rubySetBatchDimensions(final ThreadContext context, IRubyObject batchSize,
                                              IRubyObject waitForMillis) {
        setBatchDimensions(((RubyNumeric) batchSize).getIntValue(),
                ((RubyNumeric) waitForMillis).getIntValue());
        return this;
    }

    @JRubyMethod(name = "set_events_metric", required = 1)
    public IRubyObject setEventsMetric(final ThreadContext context, IRubyObject metric) {
        eventMetricOut = LongCounter.fromRubyBase(metric, OUT_KEY);
        eventMetricFiltered = LongCounter.fromRubyBase(metric, FILTERED_KEY);
        eventMetricTime = LongCounter.fromRubyBase(metric, DURATION_IN_MILLIS_KEY);
        return this;
    }

    @JRubyMethod(name = "set_pipeline_metric", required = 1)
    public IRubyObject setPipelineMetric(final ThreadContext context, IRubyObject metric) {
        pipelineMetricOut = LongCounter.fromRubyBase(metric, OUT_KEY);
        pipelineMetricFiltered = LongCounter.fromRubyBase(metric, FILTERED_KEY);
        pipelineMetricTime = LongCounter.fromRubyBase(metric, DURATION_IN_MILLIS_KEY);
        return this;
    }

    @JRubyMethod(name = "inflight_batches")
    public IRubyObject rubyGetInflightBatches(final ThreadContext context) {
        return RubyHash.newHash(context.runtime, inflightBatches, RubyBasicObject.UNDEF);
    }

    // create a new, empty batch
    @JRubyMethod(name = "new_batch")
    public IRubyObject newBatch(final ThreadContext context) {
        return JrubyMemoryReadBatchExt.create();
    }

    @JRubyMethod(name = "read_batch")
    public IRubyObject readBatch(final ThreadContext context) throws InterruptedException {
        JrubyMemoryReadBatchExt batch = JrubyMemoryReadBatchExt.create(
                LsQueueUtils.drain(queue, batchSize, waitForNanos));
        startMetrics(batch);
        return batch;
    }

    @JRubyMethod(name = "start_metrics")
    public IRubyObject rubyStartMetrics(final ThreadContext context, IRubyObject batch) {
        startMetrics((JrubyMemoryReadBatchExt) batch);
        return this;
    }

    private void startMetrics(JrubyMemoryReadBatchExt batch) {
        long threadId = Thread.currentThread().getId();
        inflightBatches.put(threadId, batch);
        inflightClocks.put(threadId, System.nanoTime());
    }

    @JRubyMethod(name = "close_batch", required = 1)
    public IRubyObject closeBatch(final ThreadContext context, IRubyObject batch) {
        JrubyMemoryReadBatchExt typedBatch = (JrubyMemoryReadBatchExt) batch;
        inflightBatches.remove(Thread.currentThread().getId());
        Long startTime = inflightClocks.remove(Thread.currentThread().getId());
        if (startTime != null && typedBatch.filteredSize() > 0) {
            // stop timer and record metrics iff the batch is non-empty.
            long elapsedTimeMillis = (System.nanoTime() - startTime) / 1_000_000;
            eventMetricTime.increment(elapsedTimeMillis);
            pipelineMetricTime.increment(elapsedTimeMillis);
        }
        return this;
    }

    @JRubyMethod(name = "add_filtered_metrics", required = 1)
    public IRubyObject addFilteredMetrics(final ThreadContext context, IRubyObject filteredSize) {
        int typedFilteredSize = ((RubyNumeric) filteredSize).getIntValue();
        eventMetricFiltered.increment(typedFilteredSize);
        pipelineMetricFiltered.increment(typedFilteredSize);
        return this;
    }

    @JRubyMethod(name = "add_output_metrics", required = 1)
    public IRubyObject addOutputMetrics(final ThreadContext context, IRubyObject filteredSize) {
        int typedFilteredSize = ((RubyNumeric) filteredSize).getIntValue();
        eventMetricOut.increment(typedFilteredSize);
        pipelineMetricOut.increment(typedFilteredSize);
        return this;
    }

}
