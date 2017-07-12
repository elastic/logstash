package org.logstash.instrument.metrics;

import java.util.concurrent.atomic.AtomicReference;

/**
 * Created by andrewvc on 5/30/17.
 */
public class Gauge<T> {
    private volatile T value;

    public Gauge(T initialValue) {
        this.value = initialValue;
    }

    public void set(T newValue) {
        this.value = newValue;
    };

    public T get() {
        return this.value;
    };
}
