package org.logstash.instrument.metrics;

import org.HdrHistogram.Histogram;

public class HistogramCapture extends DatapointCapture {

    private final Histogram hdrHistogram;

    public HistogramCapture(Histogram histogram, long nanoTime) {
        super(nanoTime);
        this.hdrHistogram = histogram;
    }

    public Histogram getHdrHistogram() {
        return hdrHistogram;
    }
}
