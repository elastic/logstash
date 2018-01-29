package org.logstash.ext;

import java.util.concurrent.ConcurrentHashMap;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyHash;
import org.jruby.RubyNumeric;
import org.jruby.RubyObject;
import org.jruby.RubySymbol;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.instrument.metrics.counter.LongCounter;

@JRubyClass(name = "AckedReadClient")
public final class JrubyAckedReadClientExt extends RubyObject {

    private static final RubySymbol OUT_KEY = RubyUtil.RUBY.newSymbol("out");
    private static final RubySymbol FILTERED_KEY = RubyUtil.RUBY.newSymbol("filtered");
    private static final RubySymbol DURATION_IN_MILLIS_KEY =
        RubyUtil.RUBY.newSymbol("duration_in_millis");

    private final ConcurrentHashMap<Long, IRubyObject> inflightBatches = new ConcurrentHashMap<>();

    private final ConcurrentHashMap<Long, Long> inflightClocks = new ConcurrentHashMap<>();

    private IRubyObject queue;
    private IRubyObject batchSize;
    private IRubyObject waitForMillis;
    private LongCounter eventMetricOut;
    private LongCounter eventMetricFiltered;
    private LongCounter eventMetricTime;
    private LongCounter pipelineMetricOut;
    private LongCounter pipelineMetricFiltered;
    private LongCounter pipelineMetricTime;

    @JRubyMethod(meta = true, required = 1)
    public static JrubyAckedReadClientExt create(final ThreadContext context,
        final IRubyObject recv, final IRubyObject queue) {
        return new JrubyAckedReadClientExt(
            context.runtime, RubyUtil.ACKED_READ_CLIENT_CLASS, queue
        );
    }

    public JrubyAckedReadClientExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    private JrubyAckedReadClientExt(final Ruby runtime, final RubyClass metaClass,
        final IRubyObject queue) {
        super(runtime, metaClass);
        this.queue = queue;
    }

    @JRubyMethod(name = "close")
    public void rubyClose(final ThreadContext context) {
        queue.callMethod(context, "close");
    }

    public boolean isEmpty() {
        return rubyIsEmpty(RubyUtil.RUBY.getCurrentContext()).isTrue();
    }

    @JRubyMethod(name = "empty?")
    public IRubyObject rubyIsEmpty(final ThreadContext context) {
        return queue.callMethod(context, "is_empty?");
    }

    @JRubyMethod(name = "set_batch_dimensions")
    public IRubyObject rubySetBatchDimensions(final ThreadContext context, IRubyObject batchSize,
        IRubyObject waitForMillis) {
        this.batchSize = batchSize;
        this.waitForMillis = waitForMillis;
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
        final RubyHash result = RubyHash.newHash(context.runtime);
        result.putAll(inflightBatches);
        return result;
    }

    @JRubyMethod(name = "new_batch")
    public IRubyObject newBatch(final ThreadContext context) {
        return JrubyAckedReadBatchExt.create(
            context, queue, context.runtime.newFixnum(0),
            context.runtime.newFixnum(0)
        );
    }

    @JRubyMethod(name = "read_batch")
    public IRubyObject readBatch(final ThreadContext context) {
        JrubyAckedReadBatchExt batch =
            JrubyAckedReadBatchExt.create(context, queue, batchSize, waitForMillis);
        startMetrics(batch);
        return batch;
    }

    @JRubyMethod(name = "start_metrics")
    public IRubyObject rubyStartMetrics(final ThreadContext context, IRubyObject batch) {
        startMetrics((JrubyAckedReadBatchExt) batch);
        return this;
    }

    @JRubyMethod(name = "close_batch", required = 1)
    public IRubyObject closeBatch(final ThreadContext context, IRubyObject batch) {
        JrubyAckedReadBatchExt typedBatch = (JrubyAckedReadBatchExt) batch;
        typedBatch.close(context);
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

    private void startMetrics(JrubyAckedReadBatchExt batch) {
        long threadId = Thread.currentThread().getId();
        inflightBatches.put(threadId, batch);
        inflightClocks.put(threadId, System.nanoTime());
    }
}
