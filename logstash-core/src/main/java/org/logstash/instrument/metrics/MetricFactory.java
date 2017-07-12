package org.logstash.instrument.metrics;

import java.util.List;

/**
 * Created by andrewvc on 5/30/17.
 */
public interface MetricFactory {
    <T> Gauge<T> makeGauge(List<String> namespace, String key, T initialValue);
    Counter makeCounter(List<String> namespace, String key, long initialValue);
}
