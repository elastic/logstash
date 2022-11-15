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


package org.logstash.execution;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyHash;
import org.jruby.RubyNumeric;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.Block;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.instrument.metrics.AbstractNamespacedMetricExt;
import org.logstash.instrument.metrics.MetricKeys;
import org.logstash.instrument.metrics.timer.TimerMetric;
import org.logstash.instrument.metrics.counter.LongCounter;

import java.io.IOException;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.TimeUnit;

/**
 * Common code shared by Persistent and In-Memory queues clients implementation
 * */
@JRubyClass(name = "QueueReadClientBase")
public abstract class QueueReadClientBase extends RubyObject implements QueueReadClient {

    private static final long serialVersionUID = 1L;

    protected int batchSize = 125;
    protected long waitForNanos = 50 * 1000 * 1000; // 50 millis to nanos
    protected long waitForMillis = 50;

    private final ConcurrentHashMap<Long, QueueBatch> inflightBatches = new ConcurrentHashMap<>();
    private transient LongCounter eventMetricOut;
    private transient LongCounter eventMetricFiltered;
    private transient TimerMetric eventMetricTime;
    private transient LongCounter pipelineMetricOut;
    private transient LongCounter pipelineMetricFiltered;
    private transient TimerMetric pipelineMetricTime;

    protected QueueReadClientBase(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @JRubyMethod(name = "inflight_batches")
    public RubyHash rubyGetInflightBatches(final ThreadContext context) {
        final RubyHash result = RubyHash.newHash(context.runtime);
        result.putAll(inflightBatches);
        return result;
    }

    @JRubyMethod(name = "set_events_metric")
    public IRubyObject setEventsMetric(final IRubyObject metric) {
        final AbstractNamespacedMetricExt namespacedMetric = (AbstractNamespacedMetricExt) metric;
        synchronized(namespacedMetric.getMetric()) {
            eventMetricOut = LongCounter.fromRubyBase(namespacedMetric, MetricKeys.OUT_KEY);
            eventMetricFiltered = LongCounter.fromRubyBase(namespacedMetric, MetricKeys.FILTERED_KEY);
            eventMetricTime = TimerMetric.fromRubyBase(namespacedMetric, MetricKeys.DURATION_IN_MILLIS_KEY);
        }
        return this;
    }

    @JRubyMethod(name = "set_pipeline_metric")
    public IRubyObject setPipelineMetric(final IRubyObject metric) {
        final AbstractNamespacedMetricExt namespacedMetric = (AbstractNamespacedMetricExt) metric;
        synchronized(namespacedMetric.getMetric()) {
            pipelineMetricOut = LongCounter.fromRubyBase(namespacedMetric, MetricKeys.OUT_KEY);
            pipelineMetricFiltered = LongCounter.fromRubyBase(namespacedMetric, MetricKeys.FILTERED_KEY);
            pipelineMetricTime = TimerMetric.fromRubyBase(namespacedMetric, MetricKeys.DURATION_IN_MILLIS_KEY);
        }
        return this;
    }

    @JRubyMethod(name = "set_batch_dimensions")
    public IRubyObject rubySetBatchDimensions(final IRubyObject batchSize,
        final IRubyObject waitForMillis) {
        setBatchDimensions(((RubyNumeric) batchSize).getIntValue(),
                ((RubyNumeric) waitForMillis).getIntValue());
        return this;
    }

    public void setBatchDimensions(int batchSize, int waitForMillis) {
        this.batchSize = batchSize;
        this.waitForNanos = TimeUnit.NANOSECONDS.convert(waitForMillis, TimeUnit.MILLISECONDS);
        this.waitForMillis = waitForMillis;
    }

    @JRubyMethod(name = "empty?")
    public IRubyObject rubyIsEmpty(final ThreadContext context) {
        return context.runtime.newBoolean(isEmpty());
    }

    @JRubyMethod(name = "close")
    public void rubyClose(final ThreadContext context) {
        try {
            close();
        } catch (IOException e) {
            throw RubyUtil.newRubyIOError(context.runtime, e);
        }
    }

    @JRubyMethod(name = "read_batch")
    public IRubyObject rubyReadBatch(final ThreadContext context) throws InterruptedException {
        return RubyUtil.toRubyObject(readBatch());
    }

    @Override
    public void closeBatch(QueueBatch batch) throws IOException {
        batch.close();
        inflightBatches.remove(Thread.currentThread().getId());
    }

    /**
     * Closes the specified batch. This JRuby extension method is currently used only in the
     * original pipeline and rspec tests.
     * @param batch specified batch
     * @throws IOException if an IO error occurs
     */
    @JRubyMethod(name = "close_batch")
    public void rubyCloseBatch(final IRubyObject batch) throws IOException {
        closeBatch(extractQueueBatch(batch));
    }

    /**
     * Initializes metric on the specified batch. This JRuby extension method is currently used
     * only in the original pipeline and rspec tests.
     * @param batch specified batch
     */
    @JRubyMethod(name = "start_metrics")
    public void rubyStartMetrics(final IRubyObject batch) {
        startMetrics(extractQueueBatch(batch));
    }

    /**
     * Extracts QueueBatch from one of two possible IRubyObject classes. Only the Ruby pipeline
     * uses JavaProxy instances, so once that is fully deprecated, this method can be simplified
     * to eliminate the type check.
     * @param batch specified IRubyObject batch
     * @return Extracted queue batch
     */
    private static QueueBatch extractQueueBatch(final IRubyObject batch) {
        return JavaUtil.unwrapIfJavaObject(batch);
    }

    /**
     * Increments the filter metrics. This JRuby extension method is currently used
     * only in the original pipeline and rspec tests.
     * @param size numeric value by which to increment metric
     */
    @JRubyMethod(name = "add_filtered_metrics")
    public void rubyAddFilteredMetrics(final IRubyObject size) {
        addFilteredMetrics(((RubyNumeric)size).getIntValue());
    }

    /**
     * Increments the output metrics. This JRuby extension method is currently used
     * only in the original pipeline and rspec tests.
     * @param size numeric value by which to increment metric
     */
    @JRubyMethod(name = "add_output_metrics")
    public void rubyAddOutputMetrics(final IRubyObject size) {
        addOutputMetrics(((RubyNumeric)size).getIntValue());
    }

    @Override
    public void startMetrics(QueueBatch batch) {
        long threadId = Thread.currentThread().getId();
        inflightBatches.put(threadId, batch);
    }

    @Override
    public void addFilteredMetrics(int filteredSize) {
        eventMetricFiltered.increment(filteredSize);
        pipelineMetricFiltered.increment(filteredSize);
    }

    @Override
    public void addOutputMetrics(int filteredSize) {
        eventMetricOut.increment(filteredSize);
        pipelineMetricOut.increment(filteredSize);
    }

    @Override
    public <V, E extends Exception> V executeWithTimers(final co.elastic.logstash.api.TimerMetric.ExceptionalSupplier<V,E> supplier) throws E {
        return eventMetricTime.time(() -> pipelineMetricTime.time(supplier));
    }

    @Override
    public <E extends Exception> void executeWithTimers(co.elastic.logstash.api.TimerMetric.ExceptionalRunnable<E> runnable) throws E {
        eventMetricTime.time(() -> pipelineMetricTime.time(runnable));
    }

    @JRubyMethod(name = "execute_with_timers")
    public IRubyObject executeWithTimersRuby(final ThreadContext context,
                                             final Block block) {
        return executeWithTimers(() -> block.call(context));
    }

    public abstract void close() throws IOException;
}
