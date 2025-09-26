package org.logstash.instrument.metrics;

import org.logstash.instrument.metrics.timer.TimerMetric;

import java.util.function.LongSupplier;

public class VisibilityUtil {
    private VisibilityUtil() {}

    public static UptimeMetric createUptimeMetric(String name, LongSupplier nanoTimeSupplier) {
        return new UptimeMetric(name, nanoTimeSupplier);
    }
}
