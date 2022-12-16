package org.logstash.execution;

import org.logstash.config.ir.CompiledPipeline;
import org.logstash.instrument.metrics.AbstractNamespacedMetricExt;
import org.logstash.instrument.metrics.MetricKeys;
import org.logstash.instrument.metrics.counter.LongCounter;
import org.logstash.instrument.metrics.timer.TimerMetric;

public class WorkerObserver {
    private final transient LongCounter processEventsFilteredMetric;
    private final transient LongCounter processEventsOutMetric;
    private final transient TimerMetric processEventsDurationMetric;

    private final transient LongCounter pipelineEventsFilteredMetric;
    private final transient LongCounter pipelineEventsOutMetric;
    private final transient TimerMetric pipelineEventsDurationMetric;

    public WorkerObserver(final AbstractNamespacedMetricExt processEventsMetric,
                          final AbstractNamespacedMetricExt pipelineEventsMetric) {
        synchronized(processEventsMetric.getMetric()) {
            this.processEventsOutMetric = LongCounter.fromRubyBase(processEventsMetric, MetricKeys.OUT_KEY);
            this.processEventsFilteredMetric = LongCounter.fromRubyBase(processEventsMetric, MetricKeys.FILTERED_KEY);
            this.processEventsDurationMetric = TimerMetric.fromRubyBase(processEventsMetric, MetricKeys.DURATION_IN_MILLIS_KEY);
        }

        synchronized(pipelineEventsMetric.getMetric()) {
            this.pipelineEventsOutMetric = LongCounter.fromRubyBase(pipelineEventsMetric, MetricKeys.OUT_KEY);
            this.pipelineEventsFilteredMetric = LongCounter.fromRubyBase(pipelineEventsMetric, MetricKeys.FILTERED_KEY);
            this.pipelineEventsDurationMetric = TimerMetric.fromRubyBase(pipelineEventsMetric, MetricKeys.DURATION_IN_MILLIS_KEY);
        }
    }

    public <QB extends QueueBatch> ObservedExecution<QB> ofExecution(final CompiledPipeline.Execution<QB> execution) {
        return new ObservedExecution<>(this, execution);
    }

    <E extends Exception> int observeExecutionComputation(final QueueBatch batch, final co.elastic.logstash.api.TimerMetric.ExceptionalSupplier<Integer,E> supplier) throws E {
        return executeWithTimers(() -> {
            final int outputCount = supplier.get();
            final int filteredCount = batch.filteredSize();

            incrementFilteredMetrics(filteredCount);
            incrementOutMetrics(outputCount);

            return outputCount;
        });
    }

    public <V, E extends Exception> V executeWithTimers(final co.elastic.logstash.api.TimerMetric.ExceptionalSupplier<V,E> supplier) throws E {
        return processEventsDurationMetric.time(() -> pipelineEventsDurationMetric.time(supplier));
    }

    private void incrementOutMetrics(final long amount) {
        this.processEventsOutMetric.increment(amount);
        this.pipelineEventsOutMetric.increment(amount);
    }

    private void incrementFilteredMetrics(final long amount) {
        this.processEventsFilteredMetric.increment(amount);
        this.pipelineEventsFilteredMetric.increment(amount);
    }

}
