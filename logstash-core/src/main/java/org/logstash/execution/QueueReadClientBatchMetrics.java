package org.logstash.execution;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.jruby.runtime.ThreadContext;
import org.logstash.ackedqueue.QueueFactoryExt;
import org.logstash.ext.JrubyEventExtLibrary;
import org.logstash.instrument.metrics.AbstractNamespacedMetricExt;
import org.logstash.instrument.metrics.HdrHistogramFlowMetric;
import org.logstash.instrument.metrics.HistogramFlowMetric;
import org.logstash.instrument.metrics.counter.LongCounter;
import org.logstash.instrument.metrics.gauge.LazyDelegatingGauge;

import java.security.SecureRandom;
import java.util.Arrays;

import static org.logstash.instrument.metrics.MetricKeys.*;

class QueueReadClientBatchMetrics {

    private static final Logger LOG = LogManager.getLogger(QueueReadClientBatchMetrics.class);

    private final QueueFactoryExt.BatchMetricMode batchMetricMode;

    private LongCounter pipelineMetricBatchCount;
    private LongCounter pipelineMetricBatchByteSize;
    private LongCounter pipelineMetricBatchTotalEvents;
    private HistogramFlowMetric pipelineMetricBatchByteSizeFlowHistogram;
    private HistogramFlowMetric pipelineMetricBatchEventCountFlowHistogram;
    private final SecureRandom random = new SecureRandom();
    private LazyDelegatingGauge currentBatchDimensions;

    public QueueReadClientBatchMetrics(QueueFactoryExt.BatchMetricMode batchMetricMode) {
        this.batchMetricMode = batchMetricMode;
    }

    public void setupMetrics(AbstractNamespacedMetricExt namespacedMetric) {
        LOG.debug("setupMetrics called with mode: {}", batchMetricMode);
        ThreadContext context = namespacedMetric.getRuntime().getCurrentContext();
        AbstractNamespacedMetricExt batchNamespace = namespacedMetric.namespace(context, BATCH_KEY);
        if (batchMetricMode != QueueFactoryExt.BatchMetricMode.DISABLED) {
            pipelineMetricBatchCount = LongCounter.fromRubyBase(batchNamespace, BATCH_COUNT);
            pipelineMetricBatchTotalEvents = LongCounter.fromRubyBase(batchNamespace, BATCH_TOTAL_EVENTS);
            pipelineMetricBatchByteSize = LongCounter.fromRubyBase(batchNamespace, BATCH_TOTAL_BYTES);
            currentBatchDimensions = LazyDelegatingGauge.fromRubyBase(batchNamespace, BATCH_CURRENT_KEY);
            pipelineMetricBatchByteSizeFlowHistogram = batchNamespace.asApiMetric()
                    .namespace("batch_byte_size")
                    .register("histogram", HdrHistogramFlowMetric.FACTORY);
            pipelineMetricBatchEventCountFlowHistogram = batchNamespace.asApiMetric()
                    .namespace("batch_event_count")
                    .register("histogram", HdrHistogramFlowMetric.FACTORY);
        }
    }

    public void updateBatchMetrics(QueueBatch batch) {
        if (batchMetricMode == QueueFactoryExt.BatchMetricMode.DISABLED) {
            return;
        }

        if (batch.events().isEmpty()) {
            // don't update averages for empty batches, but set current back to zero
            currentBatchDimensions.set(Arrays.asList(0L, 0L));
            return;
        }

        boolean updateMetric = true;
        if (batchMetricMode == QueueFactoryExt.BatchMetricMode.MINIMAL) {
            // 1% chance to update metric
            updateMetric = random.nextInt(100) < 2;
        }

        if (updateMetric) {
            updateBatchSizeMetric(batch);
        }
    }

    private void updateBatchSizeMetric(QueueBatch batch) {
        try {
            // if an error occurs in estimating the size of the batch, no counter has to be updated
            long totalByteSize = 0L;
            for (JrubyEventExtLibrary.RubyEvent rubyEvent : batch.events()) {
                totalByteSize += rubyEvent.getEvent().estimateMemory();
            }
            pipelineMetricBatchCount.increment();
            int batchEventsCount = batch.filteredSize();
            pipelineMetricBatchTotalEvents.increment(batchEventsCount);
            pipelineMetricBatchByteSize.increment(totalByteSize);
            currentBatchDimensions.set(Arrays.asList(batchEventsCount, totalByteSize));
            pipelineMetricBatchByteSizeFlowHistogram.recordValue(totalByteSize);
            pipelineMetricBatchEventCountFlowHistogram.recordValue(batchEventsCount);
        } catch (IllegalArgumentException e) {
            LOG.error("Failed to calculate batch byte size for metrics", e);
        }
    }
}
