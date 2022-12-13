package org.logstash.instrument.metrics;

import java.util.function.LongSupplier;

public class TestUptimeMetricFactory {
    private final LongSupplier nanoTimeSupplier;

    public TestUptimeMetricFactory(LongSupplier nanoTimeSupplier) {
        this.nanoTimeSupplier = nanoTimeSupplier;
    }

    public UptimeMetric newUptimeMetric(final String name) {
        return new UptimeMetric(name, nanoTimeSupplier);
    }
}
