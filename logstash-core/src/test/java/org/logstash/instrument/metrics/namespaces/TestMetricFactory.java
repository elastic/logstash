package org.logstash.instrument.metrics.namespaces;

import org.logstash.instrument.metrics.Counter;
import org.logstash.instrument.metrics.Gauge;
import org.logstash.instrument.metrics.MetricFactory;

import java.util.List;

/**
 * Created by andrewvc on 6/1/17.
 */
public class TestMetricFactory implements MetricFactory{

    @Override
    public <T> Gauge<T> makeGauge(List<String> namespace, String key, T initialValue) {
        return new Gauge<>(initialValue);
    }

    @Override
    public Counter makeCounter(List<String> namespace, String key, long initialValue) {
        return new Counter(initialValue);
    }
}
