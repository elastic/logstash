package org.logstash.instrument.metrics;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.logstash.instrument.metrics.histogram.HistogramMetric;

import java.util.Map;

public class BatchStructureMetric extends AbstractMetric<Map<String,Double>>{
    private static final Logger LOG = LogManager.getLogger(BatchStructureMetric.class);

    private final HistogramMetric batchHistogram;

    // TODO accept a time provider to allow for testing
    public BatchStructureMetric(final String name, final HistogramMetric batchHistogram) {
        super(name);
        this.batchHistogram = batchHistogram;
    }

    public void capture() {
        HistogramCapture histogramCapture = new HistogramCapture(batchHistogram.getValue(), System.nanoTime());
        LOG.trace("Captured batch structure metric: {}", histogramCapture);
        // TODO append this capture to the retention window
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
}
