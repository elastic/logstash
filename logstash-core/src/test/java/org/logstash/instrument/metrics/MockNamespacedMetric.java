package org.logstash.instrument.metrics;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubySymbol;
import org.jruby.runtime.Block;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.instrument.metrics.counter.LongCounter;
import org.logstash.instrument.metrics.histogram.HistogramMetric;
import org.logstash.instrument.metrics.timer.TimerMetric;

import java.util.Objects;

/**
 * Trivial implementation of AbstractNamespacedMetricExt where each abstract creation
 * metric is implemented by instantiating a newly fresh metric object.
 * */
@SuppressWarnings({"rawtypes", "serializable"})
public class MockNamespacedMetric extends AbstractNamespacedMetricExt {

    private static final long serialVersionUID = -6507123659910450215L;

    public static MockNamespacedMetric create() {
        return new MockNamespacedMetric(RubyUtil.RUBY, RubyUtil.NAMESPACED_METRIC_CLASS);
    }

    MockNamespacedMetric(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @Override
    protected IRubyObject getGauge(ThreadContext context, IRubyObject key, IRubyObject value) {
        return null;
    }

    @Override
    protected RubyArray getNamespaceName(ThreadContext context) {
        return null;
    }

    @Override
    protected IRubyObject getCounter(ThreadContext context, IRubyObject key) {
        Objects.requireNonNull(key);
        requireRubySymbol(key, "key");
        return RubyUtil.toRubyObject(new LongCounter(key.asJavaString()));
    }

    @Override
    protected IRubyObject getTimer(ThreadContext context, IRubyObject key) {
        Objects.requireNonNull(key);
        requireRubySymbol(key, "key");
//        return RubyUtil.toRubyObject(TimerMetric.create("test_timer"));
        return RubyUtil.toRubyObject(TimerMetric.create(key.asJavaString()));
    }

    @Override
    protected IRubyObject getHistogram(ThreadContext context, IRubyObject key) {
        Objects.requireNonNull(key);
        requireRubySymbol(key, "key");

//        HistogramMetric metric = new HistogramMetric("test_batch_metric");
        return RubyUtil.toRubyObject(new HistogramMetric(key.asJavaString()));
    }

    @Override
    protected IRubyObject doTime(ThreadContext context, IRubyObject key, Block block) {
        return null;
    }

    @Override
    protected IRubyObject doReportTime(ThreadContext context, IRubyObject key, IRubyObject duration) {
        return null;
    }

    @Override
    protected IRubyObject doIncrement(ThreadContext context, IRubyObject[] args) {
        return null;
    }

    @Override
    protected IRubyObject doDecrement(ThreadContext context, IRubyObject[] args) {
        return null;
    }

    @Override
    public AbstractMetricExt getMetric() {
        return NullMetricExt.create();
    }

    @Override
    protected AbstractNamespacedMetricExt createNamespaced(ThreadContext context, IRubyObject name) {
        return null;
    }

    @Override
    protected IRubyObject getCollector(ThreadContext context) {
        return null;
    }

    private static void requireRubySymbol(IRubyObject value, String paramName) {
        if (!(value instanceof RubySymbol)) {
            throw new IllegalArgumentException(paramName + " must be a RubySymbol instead was: " + value.getClass());
        }
    }
}