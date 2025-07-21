package org.logstash.instrument.metrics.histogram;

import org.HdrHistogram.Histogram;
import org.HdrHistogram.Recorder;
import org.jruby.RubySymbol;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.instrument.metrics.AbstractMetric;
import org.logstash.instrument.metrics.AbstractNamespacedMetricExt;
import org.logstash.instrument.metrics.MetricType;

public class HistogramMetric extends AbstractMetric<HistogramSnapshot> {

    private final Recorder histogramRecorder;

    private final Histogram lifetimeHistogram;

    /**
     * Constructor
     *
     *
     * @param name The name of this metric. This value may be used for display purposes.
     */
    public HistogramMetric(String name) {
        super(name);
        histogramRecorder = new Recorder(1_000_000, 3);
        lifetimeHistogram = histogramRecorder.getIntervalHistogram();
    }

    public static HistogramMetric fromRubyBase(AbstractNamespacedMetricExt metric, RubySymbol key) {
            final ThreadContext context = RubyUtil.RUBY.getCurrentContext();
            final IRubyObject histogram = metric.histogram(context, key);
            final HistogramMetric javaTimer;
            if (HistogramMetric.class.isAssignableFrom(histogram.getJavaClass())) {
                javaTimer = histogram.toJava(HistogramMetric.class);
            } else {
                throw new IllegalArgumentException("Metric " + key + " is not a histogram");
            }
            return javaTimer;
    }

    @Override
    public MetricType getType() {
        return MetricType.HISTOGRAM_LONG;
    }

    @Override
    public HistogramSnapshot getValue() {
        lifetimeHistogram.add(histogramRecorder.getIntervalHistogram());
        return new HistogramSnapshot(lifetimeHistogram);
    }

    /**
     * Adds a recorded value.
     *
     * @param value the value to record
     */
    public void update(long value) {
        histogramRecorder.recordValue(value);
    }
}
