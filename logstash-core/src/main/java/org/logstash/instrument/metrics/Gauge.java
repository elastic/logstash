package org.logstash.instrument.metrics;

import java.util.List;

/**
 * Created by andrewvc on 5/25/17.
 */
public class Gauge extends AbstractMetric {
    private volatile Object value = null;

    public Gauge(List<Object> namespaces, Object key) {
        super(namespaces, key);
    }

    @Override
    public Object getValue() {
        return value;
    }

    public void setValue(Object value) {
        this.value = value;
    }
}
