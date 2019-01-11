package org.logstash.plugin;

import org.logstash.instrument.metrics.Metric;

import java.util.List;

public interface Witnessable {
    List<Metric<?>> witness();
}
