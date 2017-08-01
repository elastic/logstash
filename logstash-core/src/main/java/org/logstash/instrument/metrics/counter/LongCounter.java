package org.logstash.instrument.metrics.counter;


import org.logstash.instrument.metrics.AbstractMetric;
import org.logstash.instrument.metrics.MetricType;

import java.util.List;
import java.util.concurrent.atomic.LongAdder;

/**
 * A {@link CounterMetric} that is backed by a {@link Long} type.
 */
public class LongCounter extends AbstractMetric<Long> implements CounterMetric<Long> {

    private static final IllegalArgumentException NEGATIVE_COUNT_EXCEPTION = new IllegalArgumentException("Counters can not be incremented by negative values");
    private LongAdder longAdder;
    private volatile boolean dirty;

    /**
     * Constructor
     *
     * @param name The name of this metric. This value may be used for display purposes.
     */
    public LongCounter(String name) {
        super(name);
        longAdder = new LongAdder();
    }

    @Override
    public MetricType getType() {
        return MetricType.COUNTER_LONG;
    }

    @Override
    public Long getValue() {
        return longAdder.longValue();
    }

    @Override
    public boolean isDirty() {
        return dirty;
    }

    @Override
    public void setDirty(boolean dirty){
        this.dirty = dirty;
    }

    @Override
    public void increment() {
        increment(1l);
    }

    @Override
    public void increment(Long by) {
        if (by < 0) {
            throw NEGATIVE_COUNT_EXCEPTION;
        }
        longAdder.add(by);
        dirty = true;
    }

    /**
     * Optimized version of {@link #increment(Long)} to avoid auto-boxing.
     * @param by The value which to increment by. Can not be negative.
     */
    public void increment(long by) {
        if (by < 0) {
            throw NEGATIVE_COUNT_EXCEPTION;
        }
        longAdder.add(by);
        dirty = true;
    }

}
