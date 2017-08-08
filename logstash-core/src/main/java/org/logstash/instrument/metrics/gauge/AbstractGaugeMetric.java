package org.logstash.instrument.metrics.gauge;

import org.logstash.instrument.metrics.AbstractMetric;

/**
 * Abstract {@link GaugeMetric} to hold the gauge value and handle the dirty state. Simplifies the contract by requiring the both the getter and setter to be the same type.
 * @param <T> The type to set and get this gauge.
 */
public abstract class AbstractGaugeMetric<T> extends AbstractMetric<T> implements GaugeMetric<T,T>{

    private boolean dirty;

    private volatile T value;

    /**
     * Constructor
     *
     * @param name The name of this metric. This value may be used for display purposes.
     */
    protected AbstractGaugeMetric(String name) {
        super(name);
    }

    /**
     * Constructor
     *
     * @param name         The name of this metric. This value may be used for display purposes.
     * @param initialValue The initial value for this {@link GaugeMetric}, may be null
     */
    public AbstractGaugeMetric(String name, T initialValue) {
        super(name);
        this.value = initialValue;
        setDirty(true);

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
    public T getValue() {
        return value;
    }


    @Override
    public void set(T value) {
        this.value = value;
        setDirty(true);
    }

}
