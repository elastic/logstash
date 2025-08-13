package org.logstash.instrument.metrics.histogram;

import com.fasterxml.jackson.annotation.JsonProperty;
import org.HdrHistogram.Histogram;

import java.io.Serializable;
import java.util.Map;

/**
 * Class to expose percentiles retrieved from an HdrHistogram.
 * */
public final class HistogramSnapshot implements Serializable {

    private static final long serialVersionUID = 4711735381843512566L;
    private final long percentile75;
    private final long percentile90;

    public HistogramSnapshot(Histogram hdrHistogram) {
        percentile75 = hdrHistogram.getValueAtPercentile(75);
        percentile90 = hdrHistogram.getValueAtPercentile(90);
    }

    @JsonProperty("p75")
    public double get75Percentile() {
        return percentile75;
    }

    @JsonProperty("p90")
    public double get90Percentile() {
        return percentile90;
    }

    @Override
    public String toString() {
        return "HistogramSnapshot{" +
                "percentile75=" + percentile75 +
                ", percentile90=" + percentile90 +
                '}';
    }
}
