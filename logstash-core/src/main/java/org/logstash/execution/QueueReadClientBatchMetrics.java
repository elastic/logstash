package org.logstash.execution;

import org.jruby.runtime.ThreadContext;
import org.logstash.ackedqueue.QueueFactoryExt;
import org.logstash.ext.JrubyEventExtLibrary;
import org.logstash.instrument.metrics.AbstractNamespacedMetricExt;
import org.logstash.instrument.metrics.counter.LongCounter;
import org.logstash.instrument.metrics.gauge.LazyDelegatingGauge;

import java.security.SecureRandom;
import java.util.Arrays;

import static org.logstash.instrument.metrics.MetricKeys.*;

class QueueReadClientBatchMetrics {
    private final QueueFactoryExt.BatchMetricType batchMetricType;

    private LongCounter pipelineMetricBatchCount;
    private LongCounter pipelineMetricBatchByteSize;
    private LongCounter pipelineMetricBatchTotalEvents;
    private final SecureRandom random = new SecureRandom();
    private LazyDelegatingGauge currentBatchDimensions;

    public QueueReadClientBatchMetrics(QueueFactoryExt.BatchMetricType batchMetricType) {
        this.batchMetricType = batchMetricType;
    }

    public void setupMetrics(AbstractNamespacedMetricExt namespacedMetric) {
        ThreadContext context = namespacedMetric.getRuntime().getCurrentContext();
        AbstractNamespacedMetricExt batchNamespace = namespacedMetric.namespace(context, BATCH_KEY);
        if (batchMetricType != QueueFactoryExt.BatchMetricType.NONE) {
            pipelineMetricBatchCount = LongCounter.fromRubyBase(batchNamespace, BATCH_COUNT);
            pipelineMetricBatchTotalEvents = LongCounter.fromRubyBase(batchNamespace, BATCH_TOTAL_EVENTS);
            pipelineMetricBatchByteSize = LongCounter.fromRubyBase(batchNamespace, BATCH_TOTAL_BYTES);
            currentBatchDimensions = LazyDelegatingGauge.fromRubyBase(batchNamespace, BATCH_CURRENT_KEY);
        }
    }

    public void updateBatchMetrics(QueueBatch batch) {
        if (batchMetricType != QueueFactoryExt.BatchMetricType.NONE) {
            boolean updateMetric = true;
            if (batchMetricType == QueueFactoryExt.BatchMetricType.MINIMAL) {
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
        for (JrubyEventExtLibrary.RubyEvent rubyEvent : batch.events()) {
            totalSize += rubyEvent.getEvent().estimateMemory();
        }
        pipelineMetricBatchByteSize.increment(totalSize);

//        currentBatchDimensions.set(String.format("%d-%d", batch.filteredSize(), totalSize));
        currentBatchDimensions.set(Arrays.asList(batch.filteredSize(), totalSize));
    }
}
