package org.logstash.execution;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.jruby.runtime.ThreadContext;
import org.logstash.ackedqueue.QueueFactoryExt;
import org.logstash.ext.JrubyEventExtLibrary;
import org.logstash.instrument.metrics.AbstractNamespacedMetricExt;
import org.logstash.instrument.metrics.counter.LongCounter;

import java.security.SecureRandom;

import static org.logstash.instrument.metrics.MetricKeys.*;

class QueueReadClientBatchMetrics {

    private static final Logger LOG = LogManager.getLogger(QueueReadClientBatchMetrics.class);

    private final QueueFactoryExt.BatchMetricMode batchMetricMode;

    private LongCounter pipelineMetricBatchCount;
    private LongCounter pipelineMetricBatchByteSize;
    private LongCounter pipelineMetricBatchTotalEvents;
    private final SecureRandom random = new SecureRandom();

    public QueueReadClientBatchMetrics(QueueFactoryExt.BatchMetricMode batchMetricMode) {
        this.batchMetricMode = batchMetricMode;
    }

    public void setupMetrics(AbstractNamespacedMetricExt namespacedMetric) {
        ThreadContext context = namespacedMetric.getRuntime().getCurrentContext();
        AbstractNamespacedMetricExt batchNamespace = namespacedMetric.namespace(context, BATCH_KEY);
        if (batchMetricMode != QueueFactoryExt.BatchMetricMode.DISABLED) {
            pipelineMetricBatchCount = LongCounter.fromRubyBase(batchNamespace, BATCH_COUNT);
            pipelineMetricBatchTotalEvents = LongCounter.fromRubyBase(batchNamespace, BATCH_TOTAL_EVENTS);
            pipelineMetricBatchByteSize = LongCounter.fromRubyBase(batchNamespace, BATCH_TOTAL_BYTES);
        }
    }

    public void updateBatchMetrics(QueueBatch batch) {
        if (batchMetricMode != QueueFactoryExt.BatchMetricMode.DISABLED) {
            boolean updateMetric = true;
            if (batchMetricMode == QueueFactoryExt.BatchMetricMode.MINIMAL) {
                // 1% chance to update metric
                updateMetric = random.nextInt(100) < 2;
            }

            if (updateMetric) {
                pipelineMetricBatchCount.increment();
                pipelineMetricBatchTotalEvents.increment(batch.filteredSize());
                updateBatchSizeMetric(batch);
            }
        }
    }

    private void updateBatchSizeMetric(QueueBatch batch) {
        long totalSize = 0L;
        try {
            for (JrubyEventExtLibrary.RubyEvent rubyEvent : batch.events()) {
                totalSize += rubyEvent.getEvent().estimateMemory();
            }
        } catch (IllegalArgumentException e) {
            LOG.error("Failed to calculate batch byte size for metrics", e);
        }
        pipelineMetricBatchByteSize.increment(totalSize);
    }
}
