package org.logstash.instrument.metrics;

import java.util.concurrent.atomic.LongAdder;

/**
 * Created by andrewvc on 5/30/17.
 */
public class Counter {
    private final LongAdder value = new LongAdder();

    public Counter(long initialValue) {
        this.value.add(initialValue);
    }

    public void increment(long v) {
        this.value.add(v);
    }

    public void increment() {
        this.increment(1);
    }

    public void decrement(long v) {
        this.value.add(-v);
    }

    public void decrement() {
        this.decrement(1);
    }

    public long get() {
        return this.value.longValue();
    }
}
