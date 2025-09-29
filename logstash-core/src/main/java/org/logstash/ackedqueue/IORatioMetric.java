package org.logstash.ackedqueue;

import co.elastic.logstash.api.UserMetric;
import org.logstash.instrument.metrics.MetricType;

/**
 * A {@code IORatioMetric} is a custom metric that tracks the ratio of input to output.
 */
interface IORatioMetric extends UserMetric<Double>, org.logstash.instrument.metrics.Metric<Double> {
    Double getValue();

    Value getLifetime();

    void incrementBy(int bytesIn, int bytesOut);

    @Override
    default MetricType getType() {
        return MetricType.USER;
    }

    // NOTE: at 100GiB/sec, this value type has capacity for ~272 years.
    interface Value {
        long bytesIn();

        long bytesOut();
    }

    Provider<IORatioMetric> PROVIDER = new Provider<>(IORatioMetric.class, new IORatioMetric() {
        @Override
        public Double getValue() {
            return Double.NaN;
        }

        @Override
        public Value getLifetime() {
            return null;
        }

        @Override
        public void incrementBy(int bytesIn, int bytesOut) {
            // no-op
        }

        @Override
        public String getName() {
            return "NULL";
        }
    });
}
