package org.logstash.instrument.metrics;

import org.HdrHistogram.Histogram;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.logstash.instrument.metrics.histogram.HistogramMetric;

import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;

public class BatchStructureMetric extends AbstractMetric<Map<String,Double>>{
    private static final Logger LOG = LogManager.getLogger(BatchStructureMetric.class);

    private final HistogramMetric batchHistogram;

    private static final List<FlowMetricRetentionPolicy> SUPPORTED_POLICIES = List.of(
            BuiltInFlowMetricRetentionPolicies.LAST_1_MINUTE,
            BuiltInFlowMetricRetentionPolicies.LAST_5_MINUTES,
            BuiltInFlowMetricRetentionPolicies.LAST_15_MINUTES
    );
    private final ConcurrentMap<FlowMetricRetentionPolicy, HistogramRetentionWindow> histogramsWindows = new ConcurrentHashMap<>();

    // TODO accept a time provider to allow for testing
    public BatchStructureMetric(final String name, final HistogramMetric batchHistogram) {
        super(name);
        this.batchHistogram = batchHistogram;
    }

    public void capture() {
        HistogramCapture histogramCapture = new HistogramCapture(batchHistogram.getValue(), System.nanoTime());
        LOG.trace("Captured batch structure metric: {}", histogramCapture);

        // Append this capture to each retention window supported
        for (FlowMetricRetentionPolicy retentionPolicy : SUPPORTED_POLICIES) {
            histogramsWindows.computeIfAbsent(retentionPolicy,
                            policy -> new HistogramRetentionWindow(policy, histogramCapture))
                    .append(histogramCapture);
        }
    }

    @Override
    public MetricType getType() {
        return MetricType.USER;
    }

    @Override
    public Map<String, Double> getValue() {
        // TODO collect these values from the retention window instead of hardcoding them
        return Map.of("p75", 75.0, "p95", 95.0, "p99", 99.0);
    }

    static class HistogramRetentionWindow extends RetentionWindow<HistogramCapture, Histogram> {

        private static final Comparator<HistogramCapture> HISTOGRAM_CAPTURE_COMPARATOR =
                Comparator.comparingLong(HistogramCapture::nanoTime);

        HistogramRetentionWindow(FlowMetricRetentionPolicy policy, HistogramCapture zeroCapture) {
            super(policy, zeroCapture);
        }

        @Override
        HistogramCapture mergeCaptures(HistogramCapture oldCapture, HistogramCapture newCapture) {
            if (oldCapture == null) {
                return newCapture;
            }
            if (newCapture == null) {
                return oldCapture;
            }

            // select newest capture because histogram is incremental and newer capture will have all the data of the
            // older one plus any new data since then, so no need to merge histograms
            return HISTOGRAM_CAPTURE_COMPARATOR.compare(oldCapture, newCapture) <= 0 ? newCapture : oldCapture;
        }

        @Override
        Optional<Histogram> calculateValue() {
            return calculateFromBaseline((compareCapture, baselineCapture) -> {
                if (compareCapture == null) { return Optional.empty(); }
                if (baselineCapture == null) { return Optional.empty(); }

                var result = compareCapture.getHdrHistogram().copy();
                result.subtract(baselineCapture.getHdrHistogram());
                return Optional.of(result);
            });
        }
    }
}
