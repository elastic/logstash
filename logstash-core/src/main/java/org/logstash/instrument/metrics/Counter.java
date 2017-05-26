package org.logstash.instrument.metrics;

import java.util.List;
import java.util.concurrent.atomic.DoubleAdder;
import java.util.concurrent.atomic.LongAdder;

/**
 * Created by andrewvc on 5/25/17.
 */
public class Counter extends AbstractMetric {
    private final DoubleAdder value = new DoubleAdder();

    public Counter(List<Object> namespaces, Object key) {
        this(namespaces, key, 0);
    }

    public Counter(List<Object> namespaces, Object key, double value) {
        super(namespaces, key);
        this.value.reset();
        this.value.add(value);
    }

    public void increment(double incValue) {
        value.add(incValue);
    }

    public void increment() {
        value.add(1);
    }

    public void decrement(double decValue) {
        value.add(-decValue);
    }

    public void decrement() {
        value.add(-1);
    }

    @Override
    public Object getValue() {
        return value.doubleValue();
    }
}
