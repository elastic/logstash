package org.logstash.plugins;

import co.elastic.logstash.api.CounterMetric;
import org.jruby.runtime.ThreadContext;
import org.logstash.instrument.metrics.AbstractNamespacedMetricExt;
import org.logstash.instrument.metrics.counter.LongCounter;

public class CounterMetricImpl implements CounterMetric {
    private LongCounter longCounter;

    public CounterMetricImpl(final ThreadContext threadContext,
                             final AbstractNamespacedMetricExt metrics,
                             final String metric) {
        this.longCounter = LongCounter.fromRubyBase(metrics, threadContext.getRuntime().newSymbol(metric));
    }

    @Override
    public void increment() {
        this.longCounter.increment();
    }

    @Override
    public void increment(final long delta) {
        this.longCounter.increment(delta);
    }

    @Override
    public long getValue() {
        return this.longCounter.getValue();
    }

    @Override
    public void reset() {
        this.longCounter.reset();
    }
}
